require 'aws/s3'

module Embarista
  # Simple interface for S3
  class S3
    SHOULD_GZIP = %w(.css .js)

    attr_reader :bucket_name, :age

    def initialize(bucket_name, opts={})
      S3.connect
      @bucket_name = bucket_name
      @root = Pathname.new(opts[:root] || '').expand_path
      @age = opts[:age] || 31536000
    end

    def store(name, file_path=name, opts={})
      opts[:access] ||= :public_read

      puts "#{bucket_name} -> #{name}"
      if file_path.is_a?(String)
        opts[:cache_control] = "max-age=#{age.to_i}"
        opts[:expires] = (Time.now + age).httpdate
        path = @root + file_path
        should_gzip = SHOULD_GZIP.include?(path.extname)
        opts[:content_encoding] = 'gzip' if should_gzip
        open(path, should_gzip) do |io|
          ::AWS::S3::S3Object.store(name, io, bucket_name, opts)
        end
      else
        ::AWS::S3::S3Object.store(name, file_path, bucket_name, opts)
      end
    end

    def read(name)
      ::AWS::S3::S3Object.find(name, bucket_name).value
    rescue ::AWS::S3::NoSuchKey
      nil
    end

    def self.connect
      ::AWS::S3::Base.establish_connection!(access_key_id: ENV['YAPP_AWS_KEY'], secret_access_key: ENV['YAPP_AWS_SECRET'])
    end

    private

    def open(path, should_gzip, &block)
      if should_gzip
        StringIO.open do |strio|
          strio.set_encoding(Encoding::BINARY)
          path.open('rb') do |f|
            streaming_deflate(f, strio)
          end
          strio.reopen(strio.string, 'r')
          yield strio
        end
      else
        path.open('rb', &block)
      end
    end

    def streaming_deflate(source_io, target_io, buffer_size = 16384)
      gz = Zlib::GzipWriter.new(target_io, Zlib::BEST_COMPRESSION)
      while(string = source_io.read(buffer_size)) do
        gz.write(string)
      end
    ensure
      gz.close if gz
    end
  end
end
