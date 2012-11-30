module Embarista
  class S3sync
    attr_reader :origin, :bucket_name, :pwd, :tmp_root, :local_manifest_path, :remote_manifest_path

    def initialize(origin, options)
      @bucket_name = options.fetch(:bucket_name)
      @local_manifest_path = options[:local_manifest_path]
      @remote_manifest_path = options[:remote_manifest_path]
      aws_key = options.fetch(:aws_key)
      aws_secret = options.fetch(:aws_secret)

      @connection = AWS::S3::Base.establish_connection!(
        :access_key_id     => aws_key,
        :secret_access_key => aws_secret
      )

      @pwd = Pathname.new('').expand_path
      @origin = origin
      @tmp_root = @pwd + @origin
    end

    def self.sync(origin, options)
      new(origin, options).sync
    end

    def store(name, file)
      puts " -> #{name}"

      opts = {
        access: :public_read
      }

      if should_gzip?(name)
        opts[:content_encoding] = 'gzip'
      end

      AWS::S3::S3Object.store(name, file, bucket_name, opts)
    end


    def sync
      delta_manifest = build_delta_manifest

      if delta_manifest.empty?
        puts 'everything is up to date'
        return
      end

      delta_manifest.values.each do |file_name|
        compressed_open(file_name) do |file|
          store(file_name, file)
        end
      end

      open(local_manifest_path) do |file|
        store(remote_manifest_file_name, file)
        store(local_manifest_file_name, file)
      end
    end

    def compressed_open(file_name)
      if should_gzip?(file_name)
        str_io = StringIO.new
        open(tmp_root.to_s + file_name) do |f|
          streaming_deflate(f, str_io)
        end
        str_io.reopen(str_io.string, "r")
        yield str_io
        str_io.close
      else
        open(tmp_root.to_s + file_name) do |f|
          yield f
        end
      end
    end

    def streaming_deflate(source_io, target_io, buffer_size = 4 * 1024)
      gz = Zlib::GzipWriter.new(target_io, Zlib::BEST_COMPRESSION)
      while(string = source_io.read(buffer_size)) do
        gz.write(string)
      end
      gz.close
    end

    def should_gzip?(name)
      name =~ /\.css|\.js\Z/
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
      @remote_manifest ||= YAML.load(AWS::S3::S3Object.find(remote_manifest_file_name, bucket_name).value)
    rescue AWS::S3::NoSuchKey
      puts 'no remote existing manifest, uploading everything'
    end

    def local_manifest
      @local_manifest ||= YAML.load_file(local_manifest_path)
    end
  end
end
