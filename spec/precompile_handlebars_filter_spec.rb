require 'spec_helper'
require 'execjs'

describe Embarista::Filters::PrecompileHandlebarsFilter do
  let(:file_wrapper_class) { MemoryFileWrapper }

  let(:input_hbs) {
<<-HBS
Hello {{foo}}
HBS
  }

  let(:input_files) {
    [
      MemoryFileWrapper.new("/path/to/input", "templates/bar/foo.handlebars", "UTF-8", input_hbs)
    ]
  }

  let(:output_root) { '/path/to/output' }

  let(:rake_application) {
    Rake::Application.new
  }

  let(:ember_template_compiler) { File.expand_path('../../vendor/ember-template-compiler.js', __FILE__) }
  let(:handlebars) { File.expand_path('../../vendor/handlebars.js', __FILE__) }

  let(:subject) {
    filter = described_class.new(:handlebars => handlebars,
                                 :ember_template_compiler => ember_template_compiler,
                                 :templates_global => 'Ember.TEMPLATES_BAZ')
    filter.file_wrapper_class = file_wrapper_class
    filter.manifest = MemoryManifest.new
    filter.last_manifest = MemoryManifest.new
    filter.input_files = input_files
    filter.output_root = output_root
    filter.rake_application = rake_application
    filter
  }

  it "should precompile ember template" do
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/templates/bar/foo.js"]

    file.should_not be_nil
    file.body.should_not be_nil
    file.body.should match(/^Ember\.TEMPLATES_BAZ\[\'bar\/foo\'\] = Ember\.Handlebars\.template\(.*\"Hello \".*\"foo\"/m)
    file.encoding.should eq('UTF-8')
  end
end
