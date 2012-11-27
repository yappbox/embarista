require 'spec_helper'

describe Embarista::Filters::ManifestUrlFilter do
  let(:file_wrapper_class) { MemoryFileWrapper }

  let(:input_js) {
<<-JS
var a = manifest_url('baz.jpg');
var b = manifest_url("baz/bar.jpg");
var c = manifest_url("doesnt-exist.jpg");
JS
  }

  let(:input_files) {
    [
      MemoryFileWrapper.new("/path/to/input", "foo/bar.js", "UTF-8", input_js)
    ]
  }

  let(:output_root) { '/path/to/output' }

  let(:urls_manifest) {
    {
      '/editor/images/baz.jpg' => '/editor/images/baz-123abc.jpg',
      '/editor/images/baz/bar.jpg' => '/editor/images/baz/bar-456def.jpg'
    }
  }

  let(:options) {
    { path: "/path/to/manifest.json",
      prefix: '/editor/images',
      prepend: "'//' + YappEditorConfig.assetsCdn + "
    }
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
    filter.urls_manifest = urls_manifest
    filter
  }

  it "rewrites manifest_url based on provided manifest and options" do
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/foo/bar.js"]
    file.body.should eq(<<-JS)
var a = ('//' + YappEditorConfig.assetsCdn + '/editor/images/baz-123abc.jpg');
var b = ('//' + YappEditorConfig.assetsCdn + '/editor/images/baz/bar-456def.jpg');
var c = ('//' + YappEditorConfig.assetsCdn + '/editor/images/doesnt-exist.jpg');
JS
    file.encoding.should eq('UTF-8')
  end

  it "gracefully rewrites manifest_url when path is not found" do
    subject.urls_manifest = nil
    tasks = subject.generate_rake_tasks
    tasks.each(&:invoke)

    file = MemoryFileWrapper.files["/path/to/output/foo/bar.js"]
    file.body.should eq(<<-JS)
var a = ('//' + YappEditorConfig.assetsCdn + '/editor/images/baz.jpg');
var b = ('//' + YappEditorConfig.assetsCdn + '/editor/images/baz/bar.jpg');
var c = ('//' + YappEditorConfig.assetsCdn + '/editor/images/doesnt-exist.jpg');
JS
    file.encoding.should eq('UTF-8')
  end
end
