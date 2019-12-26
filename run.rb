# frozen_string_literal: true

require 'fileutils'
require 'open-uri'
require 'pathname'
require 'shellwords'
require 'uri'
require 'yaml'
require 'bundler'
Bundler.require

# The URL for the SR22 AMM table of contents (displayed on the left IFrame on
# the AMM home page).
TOC_URL = URI.parse('http://servicecenters.cirrusdesign.com/tech_pubs/SR2X/pdf/AMM/SR22/html/ammtoc.html')

# The path where the TOC data is cached after being downloaded.
BOOK_PATH = Pathname.new(__FILE__).dirname.join('work', 'book.yml')

# The path where PDFs are downloaded.
PDF_PATH = Pathname.new(__FILE__).dirname.join('work', 'pdfs')

# The path where converted PostScript files are stored.
PS_PATH = Pathname.new(__FILE__).dirname.join('work', 'ps')

# The path where table of contents metadata for the final PDF is saved.
MARKS_PATH = Pathname.new(__FILE__).dirname.join('work', 'pdfmarks')

# The path where the final PDF is generated.
OUT_PATH = Pathname.new(__FILE__).dirname.join('work', 'amm.pdf')

# Stores table of contents information downloaded from the AMM website,
# consisting of multiple {Chapter Chapters}.

class Book

  # @return [String] The book title.
  attr_reader :title

  # @return [Array<Chapter>] The chapters of the book.
  attr_reader :chapters

  # @private
  def initialize(title)
    @title    = title
    @chapters = Array.new
  end

  # @return [Array<Pathname>] An ordered array of all the PDFs to merge.

  def paths
    chapters.each_with_object(Array.new) do |chapter, array|
      chapter.sections.each do |s|
        raise "PDFs not yet downloaded" unless s.downloaded?

        array << s.path
      end
    end
  end

  # @return [Array<Pathname>] An ordered array of all the converted PostScript
  #   files to merge.

  def ps_paths
    chapters.each_with_object(Array.new) do |chapter, array|
      chapter.sections.each do |s|
        raise "PDFs not yet downloaded" unless s.downloaded?

        array << s.ps_path
      end
    end
  end

  # @private
  #
  # Adds a chapter to this book.
  #
  # @param [Chapter] chapter The chapter to add.

  def add_chapter(chapter)
    chapter.instance_variable_set :@book, self
    chapters << chapter
  end

  # A chapter within the book, consisting of multiple {Section Sections}.

  class Chapter

    # @return [Integer] The chapter number. (Front Matter is given the chapter
    #   number zero.)
    attr_reader :number

    # @return [String] The chapter title.
    attr_reader :title

    # @return [Array<Section>] The sections making up this chapter.
    attr_reader :sections

    # @private
    def initialize(number, title)
      @number   = number
      @title    = title
      @sections = Array.new
    end

    # @private
    #
    # Adds a section to this chapter.
    #
    # @param [Section] section The section to add.

    def add_section(section)
      section.instance_variable_set :@chapter, self
      sections << section
    end

    # @return [String] The chapter title with the number prepended.

    def full_title
      "#{number.to_s.rjust 2, '0'} #{title}"
    end

    # @return [Integer] The page that the chapter begins at (1-indexed).
    # @raise [StandardError] If the PDFs have not yet been downloaded.

    def first_page
      previous ? previous.first_page + previous.pages : 1
    end

    # @return [Integer] The number of pages in this chapter.
    # @raise [StandardError] If the PDFs have not yet been downloaded.

    def pages
      sections.inject(0) { |sum, s| sum + s.pages }
    end

    private

    def previous
      index = @book.chapters.index(self)
      return nil if index.zero?

      @book.chapters[index - 1]
    end
  end

  # A section within a chapter. A section is initialized with a URL where the
  # PDF can be downloaded. It can then download the PDF.

  class Section

    # @return [Integer, nil] The section number, or `nil` if the section is not
    #   numbered.
    attr_reader :number

    # @return [String] The section title.
    attr_reader :title

    # @return [URI::HTTPS] The URL for the section PDF.
    attr_reader :url

    # @private
    def initialize(number, title, url)
      @number = number
      @title  = title
      @url    = url
    end

    # @return [String] The section title, with the section number prepended.

    def full_title
      number ? "#{@chapter.number.to_s.rjust 2, '0'}-#{number.to_s.rjust 2, '0'} #{title}" : title
    end

    # @return [Pathname] The path where the PDF is (or will be) downloaded to.

    def path
      PDF_PATH.join(*basename('pdf'))
    end

    # @return [Pathname] The path to the converted PostScript file.

    def ps_path
      PS_PATH.join(*basename('ps'))
    end

    # Downloads the PDF to the {#path}.

    def download!
      Net::HTTP.start(url.host, url.port, ssl: url.scheme == 'https') do |http|
        req = Net::HTTP::Get.new(url.path)
        http.request(req) do |res|
          raise("Couldn't download #{inspect}") unless res.kind_of?(Net::HTTPOK)

          FileUtils.mkdir_p(path.dirname)
          path.open('wb') do |f|
            res.read_body { |chunk| f.write chunk }
          end
        end
      end
    end

    # @return [true, false] Whether or not the PDF has been downloaded.
    # @see #download!
    def downloaded?() path.exist? end

    # Converts the PDF to a PostScript file (stripping bookmarks).

    def convert!
      FileUtils.mkdir_p(ps_path.dirname)
      system 'pdftops', path.to_s, ps_path.to_s
    end

    # @return [true, false] Whether or not the PDF has been converted to a
    #   PostScript file.
    # @see #convert!
    def converted?() ps_path.exist? end

    # @return [Integer] The first page of this section within the book
    #   (1-indexed).
    # @raise [StandardError] If any of the previous sections' PDFs has not yet
    #   been downloaded.

    def first_page
      previous ? previous.first_page + previous.pages : @chapter.first_page
    end

    # @return [Integer] The number of pages in this section.
    # @raise [StandardError] If the PDF has not yet been downloaded.

    def pages
      raise "Not yet downloaded: #{inspect}" unless downloaded?

      @pages ||= begin
        info = `pdfinfo #{Shellwords.escape path.to_s}`
        info.match(/^Pages:\s+(\d+)$/)[1].to_i
      end
    end

    private

    def basename(ext)
      return @chapter.full_title.tr('/', '-'),
          full_title.tr('/', '-') + '.' + ext
    end

    def previous
      index = @chapter.sections.index(self)
      return nil if index.zero?

      @chapter.sections[index - 1]
    end
  end
end

def build_toc
  return YAML.load_file(BOOK_PATH.to_s) if BOOK_PATH.exist?

  html  = Nokogiri::HTML(TOC_URL.open)
  title = strip(html.css('p>b').first.content)
  book  = Book.new(title)

  build_chapters(html) { |c| book.add_chapter c }

  BOOK_PATH.open('w') { |f| f.puts book.to_yaml }

  return book
end

def build_chapters(html)
  html.css('ul#x>li').each do |li|
    full_title = strip(li.children.select(&:text?).first.content)
    if full_title == "Front Matter"
      chapter = Book::Chapter.new(0, full_title)
    else
      matches = full_title.match(/^Chapter (\d+) - (.+)$/)
      number  = matches[1].to_i
      title   = matches[2]
      chapter = Book::Chapter.new(number, title)
    end

    build_sections(li) { |s| chapter.add_section s }

    yield chapter
  end
end

def build_sections(chapter_li)
  chapter_li.css('ul>li>a').each do |a|
    url     = URI.join(TOC_URL, a.attributes['href'].content)
    matches = a.content.match(/^(?:\d+-(\d+) )?(.+)$/)
    number  = matches[1]&.to_i
    title   = strip(matches[2])
    yield Book::Section.new(number, title, url)
  end
end

def download_pdfs(book)
  book.chapters.each do |chapter|
    chapter.sections.each do |section|
      next if section.downloaded?

      puts "Downloading #{section.title}..."
      section.download!
    end
  end
end

def generate_pdfmarks(book)
  return if MARKS_PATH.exist?

  MARKS_PATH.open('w') do |f|
    f.puts <<~EOS.chomp
      [ /Title (#{book.title})
        /Author (Cirrus Design Inc.)
    EOS

    book.chapters.each do |chapter|
      f.puts "[/Count -#{chapter.sections.size} /Title (#{chapter.full_title}) /Page #{chapter.first_page} /OUT pdfmark"
      chapter.sections.each do |section|
        f.puts "[/Title (#{section.full_title}) /Page #{section.first_page} /OUT pdfmark"
      end
    end
  end
end

# necessary strip existing TOC information
def convert_to_ps(book)
  book.chapters.each do |chapter|
    chapter.sections.each do |section|
      next if section.converted?

      puts "Converting #{section.title}..."
      section.convert!
    end
  end
end

def combine_pdfs(book)
  system 'gs',
         '-dBATCH',
         '-sDEVICE=pdfwrite',
         '-o', OUT_PATH.to_s,
         *book.ps_paths.map(&:to_s),
         MARKS_PATH.to_s
end

def strip(txt)
  txt.sub(/^(\s| )+/, '').sub(/(\s| )+$/, '')
end

def run
  book = build_toc
  download_pdfs(book)
  convert_to_ps(book)
  generate_pdfmarks(book)
  combine_pdfs(book)

  puts "Your AMM is at #{OUT_PATH}"
end

run
