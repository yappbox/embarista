require 'spec_helper'
require 'pathname'
require 'fileutils'

describe Embarista::ManifestBuilder do
  let(:document_root) {
    Pathname.new('public').expand_path
  }

  let(:tmp_document_root) {
    Pathname.new('tmp/public').expand_path
  }

  let(:options) {
    {}
  }

  subject {
    described_class.new(options)
  }

  its(:document_root) { should == document_root }

  its(:tmp_document_root) { should == tmp_document_root }

  its(:manifest) { should == {} }

  its(:version) { should be_nil }


  def make_file(path, contents)
    FileUtils.mkdir_p File.dirname(path)
    File.open(path, 'w') {|f| f << contents}
  end

  describe "#add" do
    before do
      make_file('public/foo/bar/hello.txt', <<-CONTENT)
Hello World!
CONTENT
      make_file('public/foo/baz/goodbye.txt', <<-CONTENT)
Goodbye Cruel World...
CONTENT
      make_file('public/foo/baz/Name With Spaces.png', <<-CONTENT)
another image
CONTENT
      make_file('images/foo.png', <<-CONTENT
image
CONTENT
)
    end

    it 'should digest and copy the file' do
      # echo 'Hello World!' | md5
      # > 8ddd8be4b179a529afa5f2ffae4b9858


      subject.add('public/foo/bar/hello.txt')
      File.exist?('tmp/public/foo/bar/hello-8ddd8be4b179a529afa5f2ffae4b9858.txt').should eq(true)
      subject.manifest.should == {
        '/foo/bar/hello.txt' => '/foo/bar/hello-8ddd8be4b179a529afa5f2ffae4b9858.txt'
      }

      subject.add('public/foo/baz/goodbye.txt')
      File.exist?('tmp/public/foo/baz/goodbye-8dcca69d946ae9576734c2c91dfddec4.txt').should eq(true)
      subject.manifest.should == {
        '/foo/bar/hello.txt' => '/foo/bar/hello-8ddd8be4b179a529afa5f2ffae4b9858.txt',
        '/foo/baz/goodbye.txt' => '/foo/baz/goodbye-8dcca69d946ae9576734c2c91dfddec4.txt'
      }

      subject.add('images/foo.png', 'editor/images/foo.png')
      File.exist?('tmp/public/editor/images/foo-4802fcebd761ca4f04c9a6320330fd10.png').should eq(true)
      subject.manifest.should == {
        '/foo/bar/hello.txt' => '/foo/bar/hello-8ddd8be4b179a529afa5f2ffae4b9858.txt',
        '/foo/baz/goodbye.txt' => '/foo/baz/goodbye-8dcca69d946ae9576734c2c91dfddec4.txt',
        '/editor/images/foo.png' => '/editor/images/foo-4802fcebd761ca4f04c9a6320330fd10.png'
      }

      subject.add('public/foo/baz/Name With Spaces.png')
      File.exist?('tmp/public/foo/baz/Name With Spaces-147a09c8e7f061986ce3edfc920e9e0f.png').should eq(true)
      subject.manifest.should == {
        '/foo/bar/hello.txt' => '/foo/bar/hello-8ddd8be4b179a529afa5f2ffae4b9858.txt',
        '/foo/baz/goodbye.txt' => '/foo/baz/goodbye-8dcca69d946ae9576734c2c91dfddec4.txt',
        '/editor/images/foo.png' => '/editor/images/foo-4802fcebd761ca4f04c9a6320330fd10.png',
        '/foo/baz/Name%20With%20Spaces.png' => '/foo/baz/Name%20With%20Spaces-147a09c8e7f061986ce3edfc920e9e0f.png'
      }
    end
  end
end
