require 'embarista'
require 'fileutils'

require "spec_helpers/memory_file_wrapper"
require "spec_helpers/memory_manifest"
require 'rspec/its'

RSpec.configure do |config|
  original = Dir.pwd

  config.include FileUtils

  config.expect_with(:rspec) { |c| c.syntax = :should }

  def tmp
    File.expand_path("../tmp", __FILE__)
  end

  config.before do
    rm_rf(tmp)
    mkdir_p(tmp)
    Dir.chdir(tmp)
  end

  config.after do
    Dir.chdir(original)
  end
end
