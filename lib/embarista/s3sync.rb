require 'embarista/s3'

module Embarista
  class S3sync
    attr_reader :local_manifest_path, :remote_manifest_path, :s3

    def initialize(root, opts={})
      @local_manifest_path = opts[:local_manifest_path]
      @remote_manifest_path = opts[:remote_manifest_path]
      @root = Pathname.new(root).expand_path
      @s3 = S3.new(opts.fetch(:bucket_name), root: root) 
    end

    def self.sync(root, opts={})
      new(root, opts).sync
    end

    def sync
      delta_manifest = build_delta_manifest

      if delta_manifest.empty?
        puts 'everything is up to date'
        return
      end

      delta_manifest.values.each do |file_name|
        file_name[0] = ''
        s3.store(file_name)
      end

      s3.store(remote_manifest_file_name, local_manifest_path)
      s3.store(local_manifest_file_name, local_manifest_path)
    end

    def remote_manifest_file_name
      File.basename(remote_manifest_path)
    end

    def local_manifest_file_name
      File.basename(local_manifest_path)
    end

    def build_delta_manifest
      return local_manifest unless remote_manifest

      new_manifest_values = local_manifest.values - remote_manifest.values

      local_manifest.select {|key, value| new_manifest_values.include? value }
    end

    def remote_manifest
      @remote_manifest ||= begin
        if remote_manifest = s3.read(remote_manifest_file_name)
          YAML.load(remote_manifest)
        else
          puts 'no remote existing manifest, uploading everything'
          nil
        end
      end
    end

    def local_manifest
      @local_manifest ||= YAML.load_file(@root + local_manifest_path)
    end
  end
end
