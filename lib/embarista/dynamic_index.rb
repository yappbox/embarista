require 'rake'
require 'rake/tasklib'

module Embarista
  module DynamicIndex
    class Generator
      attr_reader :env_config, :yapp_env, :manifest_id, :yapp_config

      def initialize(erb_path, manifest_id)
        @erb_path = erb_path
        @env_config = Yapp.load_config
        @yapp_env = ENV.fetch('YAPP_ENV').to_sym
        @yapp_config = env_config.fetch(yapp_env)
        @manifest_id = manifest_id
        prepare_manifest
      end

      def prepare_manifest
        if @manifest_id == 'dev'
          @manifest = {}
        else
          #TODO: ensure the manifest is on s3
          @manifest = YAML.load_file("tmp/public/#{@manifest_id}.yml")
        end
      end

      def manifest_url(source)
        source = @manifest[source] || source
        "//#{yapp_config.domains.assets_cdn}#{source}"
      end

      def html
        File.open(@erb_path) do |f|
          erb = ERB.new(f.read, nil, '-')
          erb.result(binding)
        end
      end
    end

    class Middleware
      def initialize(app, opts = {})
        @app = app
        @erb_path = opts[:erb] || 'app/index.html.erb'
        @path_info = opts.fetch(:path_info)
        @generator = Embarista::DynamicIndex::Generator.new(@erb_path, 'dev')
      end

      def call(env)
        path = env["PATH_INFO"]
        if path == @path_info
          [
            200,
            { 'Content-Type' => "text/html" },
            [ @generator.html ]
          ]
        else
          @app.call(env)
        end
      end
    end

    class Task < ::Rake::TaskLib
      attr_accessor :name, :erb_path, :app

      def initialize(name = :generate_index)
        @name = name
        @erb_path = "app/index.html.erb"
        yield self if block_given?

        raise 'app must be set' unless @app
        define
      end

      def redis_url
        ENV['REDISTOGO_URL'] ||= begin
          yapp_env = ENV.fetch('YAPP_ENV')
          redis_url = case yapp_env
          when 'dev'
            "redis://0.0.0.0:6379/"
          when 'qa'
            Bundler.with_clean_env do
              `heroku config:get REDISTOGO_URL --app qa-yapp-cedar`.chomp
            end
          when 'prod'
            Bundler.with_clean_env do
              `heroku config:get REDISTOGO_URL --app yapp-cedar`.chomp
            end
          else
            raise "don't know how to get redis connection for #{yapp_env}"
          end
        end
      end

      def redis
        $redis ||= begin
          require 'uri'
          require 'redis'

          uri = URI.parse(redis_url)

          Redis.new(
            :host => uri.host,
            :port => uri.port,
            :password => uri.password
          )
        end
      end

      def define
        task name, :manifest_id do |t, args|
          require 'redis'

          manifest_id = args[:manifest_id]
          generator = Embarista::DynamicIndex::Generator.new(erb_path, manifest_id)
          html = generator.html

          redis.set("#{app}:index:#{manifest_id}", html)
        end
      end
    end

  end
end
