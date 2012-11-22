require 'spec_helper'

describe Embarista::Filters::RewriteMinispadeRequiresFilter do
  let(:file_wrapper_class) { MemoryFileWrapper }

  let(:input_js) {
<<-JS
require('baz');
require('../baz');
require('./baz');
require('./bar/baz');
JS
  }

  let(:input_files) {
    [
      MemoryFileWrapper.new("/path/to/input", "foo/bar.js", "UTF-8", input_js)
    ]
  }

  let(:output_root) { '/path/to/output' }

  let(:options) {
    nil
  }

  let(:rake_application) {
    Rake::Application.new
  }

  let(:subject) {
    filter = described_class.new(options)
    filter.file_wrapper_class = file_wrapper_class
    filter.manifest = MemoryManifest.new
    filter.last_manifest = MemoryManifest.new
    filter.input_files = input_files
    filter.output_root = output_root
    filter.rake_application = rake_application
    filter
  }

  it "rewrites require to be relative to input" do
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/foo/bar.js"]
    file.body.should eq(<<-JS)
minispade.require('baz');
minispade.require('baz');
minispade.require('foo/baz');
minispade.require('foo/bar/baz');
JS
    file.encoding.should eq('UTF-8')
  end
end
