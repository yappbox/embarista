require 'spec_helper'

describe Embarista::Filters::ErbFilter do
  MemoryFileWrapper = Rake::Pipeline::SpecHelpers::MemoryFileWrapper

  let(:file_wrapper_class) { MemoryFileWrapper }

  let(:input_files) {
    [
      MemoryFileWrapper.new("/path/to/input", "foo.erb", "UTF-8", "Hello <%= test_var %>"),
    ]
  }

  let(:output_root) { '/path/to/output' }

  let(:test_var) { 'Bear' }

  let(:options) {
    {:binding => binding}
  }

  let(:rake_application) {
    Rake::Application.new
  }

  let(:subject) {
    filter = described_class.new(options) do |input|
      input.sub(/\.(erb)$/, '.txt')
    end
    filter.file_wrapper_class = file_wrapper_class
    filter.input_files = input_files
    filter.output_root = output_root
    filter.rake_application = rake_application
    filter
  }

  it "generates output" do
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/foo.txt"]
    file.body.should eq("Hello Bear")
    file.encoding.should eq("UTF-8")
  end
end
