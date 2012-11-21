module Embarista
  class S3sync
    attr_reader :origin, :bucket_name, :pwd, :tmp_root, :manifest_path

    def initialize(origin, options) 
      bucket_name = options.fetch(:bucket_name)
      manifest_path = options.fetch(:manifest_path)
      aws_key = options.fetch(:aws_key)
      aws_secret = options.fetch(:aws_secret)

      @connection = AWS::S3::Base.establish_connection!(
        :access_key_id     => aws_key,
        :secret_access_key => aws_secret
      )

      @pwd = Pathname.new('').expand_path
      @origin = origin
      @bucket_name = bucket_name
      @tmp_root = @pwd + @origin
      @manifest_path = manifest_path
    end

    def self.sync(origin, options)
      new(origin, options).sync
    end

    def store(name, file)
      puts " -> #{name}"
      AWS::S3::S3Object.store(name, file, bucket_name)
    end

    def sync
      delta_manifest = build_delta_manifest

      if delta_manifest.empty?
        puts 'everything is up to date'
        return
      end

      delta_manifest.values.each do |file_name|
        open(tmp_root.to_s + file_name) do |file|
          store(file_name, file)
        end
      end

      open(manifest_path) do |file|
        store('manifest-latest.yml', file)
      end
    end

    def build_delta_manifest
      return local_manifest unless remote_manifest

      new_manifest_values = local_manifest.values - remote_manifest.values
      local_manifest.invert.slice(*new_manifest_values).invert
    end

    def remote_manifest
      @remote_manifest ||= YAML.load(AWS::S3::S3Object.find('manifest-latest.yml', bucket_name).value)
    rescue AWS::S3::NoSuchKey
      puts 'no remote existing manifest, uploading everything'
    end

    def local_manifest
      @local_manifest ||= YAML.load_file('public/manifest.yml')
    end
  end
end
