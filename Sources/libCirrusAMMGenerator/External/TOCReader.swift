import Foundation
import RegexBuilder
import SwiftSoup
import libCommon

actor TOCReader {
  let url: URL

  private var session: URLSession { .init(configuration: .ephemeral) }

  private let chapterRx = Regex {
    Anchor.startOfLine
    "Chapter "
    TryCapture {
      OneOrMore(.digit)
    } transform: {
      UInt($0)
    }
    " - "
    Capture {
      OneOrMore(.any)
    }
    Anchor.endOfLine
  }

  private let sectionRx = Regex {
    Anchor.startOfLine
    Optionally {
      Regex {
        OneOrMore(.digit)
        "-"
        TryCapture {
          OneOrMore(.digit)
        } transform: {
          UInt($0)
        }
        " "
      }
    }
    Capture {
      OneOrMore(.any)
    }
    Anchor.endOfLine
  }

  init(url: URL) {
    self.url = url
  }

  func data() async throws -> BookData {
    let doc = try SwiftSoup.parse(await tocHTML())

    var book = try BookData(title: title(doc: doc))
    try chapters(doc: doc) { book.chapters.append($0) }

    return book
  }

  private func tocHTML() async throws -> String {
    let (data, response) = try await session.data(from: url)
    guard let response = response as? HTTPURLResponse else {
      throw CirrusAMMGeneratorError.downloadFailed(url: url, response: response)
    }
    guard response.statusCode / 100 == 2 else {
      throw CirrusAMMGeneratorError.downloadFailed(url: url, response: response)
    }

    guard let str = String(data: data, encoding: .windowsCP1250) else {
      throw CirrusAMMGeneratorError.badTOC
    }
    return str
  }

  private func title(doc: Document) throws -> String {
    guard let title = try doc.select("p>b").first() else {
      throw CirrusAMMGeneratorError.badTOC
    }
    return title.ownText()
  }

  private func chapters(doc: Document, handler: (ChapterData) -> Void) throws {
    var chapter: ChapterData?
    for li in try doc.select("ul#x>nobr>li") {
      let title = strip(li.ownText())

      if title.hasPrefix("Front Matter") {
        chapter = ChapterData(number: 0, title: title)
      } else if let matches = try chapterRx.wholeMatch(in: title) {
        chapter = ChapterData(number: matches.1, title: String(matches.2))
      } else {
        chapter = ChapterData(number: (chapter?.number ?? 0) + 1, title: title)
      }

      try sections(li: li) { chapter!.sections.append($0) }
      handler(chapter!)
    }
  }

  private func sections(li: Element, handler: (SectionData) -> Void) throws {
    for a in try li.select("ul>li>a") {
      let path = try a.attr("href").prefix(while: { $0 != "#" })
      let url = url.deletingLastPathComponent().appending(path: path).standardized
      guard let matches = try sectionRx.wholeMatch(in: a.ownText()) else {
        throw CirrusAMMGeneratorError.badTOC
      }

      let section = SectionData(
        number: matches.1,
        title: String(matches.2),
        url: url
      )
      handler(section)
    }
  }

  private func strip(_ text: String) -> String {
    text.replacing(#/^(\s| )+/#, with: " ")
  }
}
