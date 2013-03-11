require 'rake'
require 'rake/tasklib'
module Embarista
  module DynamicIndex
    class SetCurrentTask < ::Rake::TaskLib
      attr_accessor :name, :app

      def initialize(name = :set_current_index)
        @name = name

        yield self if block_given?

        raise 'app must be set' unless @app
        define
      end

      def yapp_env
        @yapp_env ||= (ENV['YAPP_ENV'] || 'dev')
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

      private
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
  end
end
