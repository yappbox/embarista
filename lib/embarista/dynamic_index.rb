require 'rake'
require 'rake/tasklib'

module Embarista
  module DynamicIndex
    # ENV.fetch does not behave as Hash#fetch,
    # it fails to tell you which key failed.
    def self.env_fetch(key)
      ENV[key] or raise KeyError, "key not found: \"#{key}\""
    end

    class Generator
      #TODO: remove YAPP reference
      attr_reader :env_config, :yapp_env, :manifest_id, :yapp_config

      def initialize(erb_path, manifest_id)
        @erb_path = erb_path
        #TODO: remove YAPP reference
        @env_config = Yapp.load_config

        #TODO: remove YAPP reference
        @yapp_env = Embarista::DynamicIndex.env_fetch('YAPP_ENV').to_sym

        @yapp_config = env_config.fetch(@yapp_env)
        @manifest_id = manifest_id || @yapp_env
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

      def preview_url(app)
        "https://#{yapp_config.domains.app}/#{app}/?manifest_id=#{manifest_id}"
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

    class SetCurrentTask < ::Rake::TaskLib
      attr_accessor :name, :app

      def initialize(name = :set_current_index)
        @name = name

        yield self if block_given?

        raise 'app must be set' unless @app
        define
      end

      def yapp_env
        @yapp_env ||= Embarista::DynamicIndex.env_fetch('YAPP_ENV')
      end

      def redis_url
        ENV['REDISTOGO_URL'] ||= begin

          case yapp_env
          when 'dev'
            'redis://0.0.0.0:6379/'
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
        set_current_task = task name, :manifest_id do |t, args|
          require 'redis'

          manifest_id = args[:manifest_id] || yapp_env

          puts "redis.set('#{app}:index:current', '#{manifest_id}')"
          redis.set("#{app}:index:current", manifest_id)
        end
        set_current_task.add_description "Activates a manifest in the given YAPP_ENV"
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

      def yapp_env
        @yapp_env ||= Embarista::DynamicIndex.env_fetch('YAPP_ENV')
      end

      def redis_url
        ENV['REDISTOGO_URL'] ||= begin

          case yapp_env
          when 'dev'
            'redis://0.0.0.0:6379/'
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
        generate_index_task = task name, :manifest_id do |t, args|
          require 'redis'

          manifest_id = args[:manifest_id] || yapp_env
          generator = Embarista::DynamicIndex::Generator.new(erb_path, manifest_id)
          html = generator.html

          puts "redis.set('#{app}:index:#{manifest_id}', '#{html[0,10].strip}...')"
          redis.set("#{app}:index:#{manifest_id}", html)
          puts "To preview: #{generator.preview_url(app)}"
          puts "To activate:  YAPP_ENV=#{yapp_env} rake \"deploy:set_current_index[#{manifest_id}]\""
        end
        generate_index_task.add_description "Generate a manifest for the specified YAPP_ENV, run once with dev to boostrap environment"
      end
    end
  end
end
