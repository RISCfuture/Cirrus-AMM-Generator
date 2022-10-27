# frozen_string_literal: true

D = Steep::Diagnostic

target :run do
  signature "sig"

  check "run.rb"

  library "pathname", "uri"

  repo_path "vendor/rbs/gem_rbs_collection/gems"
  library "nokogiri" #, 'async-http'

  configure_code_diagnostics(D::Ruby.strict)
end
