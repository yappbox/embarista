require 'aws-sdk-s3'
require 'zopfli'
require 'mime/types'
require 'open-uri'

module Embarista
  # Simple interface for S3
  class S3
    SHOULD_ADD_CHARSET_UTF8 = %w(.js .css .html .json .xml)
    SHOULD_GZIP_BINARY = %w(.ttf .eot .otf)
    SHOULD_GZIP_ENCODING = %w(8bit 7bit quoted-printable)
    DEFAULT_MIME_TYPE = MIME::Types['application/octet-stream'].first

    attr_reader :bucket_name, :age
    def initialize(bucket_name, opts={})
      s3 = Aws::S3::Resource.new
      @bucket = s3.bucket(bucket_name)
      @root = Pathname.new(opts[:root] || '').expand_path
      @age = opts[:age] || 31536000
    end

    def store(name, file_or_path=name, opts={})
      opts[:acl] ||= 'public-read'

      puts "#{bucket_name} -> #{name}"
      s3_object = @bucket.object(name)
      if file_or_path.is_a?(String)
        opts[:cache_control] = "max-age=#{age.to_i}"
        opts[:expires] = (Time.now + age).httpdate
        path = @root + file_or_path
        ext = path.extname
        mime_type = MIME::Types.type_for(ext).first || DEFAULT_MIME_TYPE
        opts[:content_type] = mime_type.to_s
        if SHOULD_ADD_CHARSET_UTF8.include?(ext)
          opts[:content_type] += '; charset=utf-8'
        end
        if SHOULD_GZIP_ENCODING.include?(mime_type.encoding) or SHOULD_GZIP_BINARY.include?(ext)
          opts[:content_encoding] = 'gzip'
          s3_object.put(opts.merge(body: Zopfli.deflate(path.read, format: :gzip)))
        else
          s3_object.put(opts.merge(body: path.read))
        end
      else
        s3_object.put(opts.merge(body: file_or_path))
      end
    end

    def read(name, &block)
      url = @bucket.object(name).public_url
      if block_given?
        open(url, &block)
      else
        open(url) {|io| io.read }
      end
    rescue ::AWS::S3::Errors::NoSuchKey
      nil
    end
  end
end
