require 'spec_helper'

describe Embarista::Filters::StripEmberAssertsFilter do
  MemoryFileWrapper = Rake::Pipeline::SpecHelpers::MemoryFileWrapper

  let(:file_wrapper_class) { MemoryFileWrapper }

  let(:input_js) {
<<-JS
function foo() {
  Ember.warn('do not foo');
  Ember.assert('assert something', Ember.something);
  Ember.deprecate('foo is deprecated');
  Ember.deprecateFunc('foo is deprecated', Ember.foo);
}
JS
  }

  let(:input_files) {
    [
      MemoryFileWrapper.new("/path/to/input", "foo/bar.js", "UTF-8", input_js)
    ]
  }

  let(:output_root) { '/path/to/output' }

  let(:rake_application) {
    Rake::Application.new
  }

  let(:subject) {
    filter = described_class.new
    filter.file_wrapper_class = file_wrapper_class
    filter.input_files = input_files
    filter.output_root = output_root
    filter.rake_application = rake_application
    filter
  }

  it "should strip Ember asserts, warnings and deprecations" do
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/foo/bar.js"]
    file.body.should eq(<<-JS)
function foo() {
  
  
  
  
}
JS
    file.encoding.should eq('UTF-8')
  end
end
