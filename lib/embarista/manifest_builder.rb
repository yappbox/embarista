require 'pathname'
require 'fileutils'

module Embarista
  class ManifestBuilder
    include FileUtils

    attr_reader :root, :tmp, :document_root, :tmp_document_root, :version, :manifest

    def initialize(opts={})
      @root = Pathname.new(opts[:root] || Dir.getwd).expand_path
      @document_root = Pathname.new(opts[:document_root] || 'public').expand_path(@root)
      @tmp = Pathname.new(opts[:tmp] || 'tmp').expand_path(@root)
      @tmp_document_root =  @tmp + @document_root.relative_path_from(@root)
      @manifest = opts[:manifest] || {}
      @version = opts[:version]
    end

    # Pass in the file to be versioned and staged in the tmp document root.
    def add(path, path_from_document_root=nil)
      full_path = Pathname.new(path).expand_path(root)
      path_from_document_root = Pathname.new(path_from_document_root || full_path.relative_path_from(document_root))
      relative_dir = path_from_document_root.dirname

      md5 = Digest::MD5.file(full_path).hexdigest
      ext = full_path.extname
      name_without_ext = full_path.basename.to_s.chomp(ext)
      suffix = "-#{md5}"
      suffix = "-#{version}#{suffix}" if version
      versioned_file = "#{name_without_ext}#{suffix}#{ext}"

      versioned_path_from_document_root = relative_dir + versioned_file
      versioned_full_path = tmp_document_root + versioned_path_from_document_root

      mkdir_p versioned_full_path.dirname
      cp full_path, versioned_full_path

      http_path =           '/' + path_from_document_root.to_s
      versioned_http_path = '/' + versioned_path_from_document_root.to_s

      manifest[http_path] = versioned_http_path
    end
  end
end
