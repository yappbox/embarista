require 'aws-sdk'
require 'zopfli'

module Embarista
  # Simple interface for S3
  class S3
    SHOULD_GZIP = %w(.css .js)

    attr_reader :bucket_name, :age
    def initialize(bucket_name, opts={})
      s3 = AWS::S3.new
      @bucket = s3.buckets[bucket_name]
      @root = Pathname.new(opts[:root] || '').expand_path
      @age = opts[:age] || 31536000
    end

    def store(name, file_path=name, opts={})
      opts[:acl] ||= :public_read

      puts "#{bucket_name} -> #{name}"
      s3_object = @bucket.objects[name]
      if file_path.is_a?(String)
        opts[:cache_control] = "max-age=#{age.to_i}"
        opts[:expires] = (Time.now + age).httpdate
        path = @root + file_path
        if SHOULD_GZIP.include?(path.extname)
          opts[:content_encoding] = 'gzip'
          s3_object.write(Zopfli.deflate(path.read, format: :gzip), opts)
        else
          s3_object.write(path, opts)
        end
      else
        s3_object.write(file_path, opts)
      end
    end

    def read(name)
      @bucket.objects[name].read
    rescue ::AWS::S3::Errors::NoSuchKey
      nil
    end
  end
end
