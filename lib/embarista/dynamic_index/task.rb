module Embarista
  module DynamicIndex
    class Task < ::Rake::TaskLib
      attr_accessor :name, :erb_path, :app, :redis

      def initialize(name = :generate_index)
        @name = name
        @erb_path = "app/index.html.erb"
        yield self if block_given?

        @redis ||= Redis.client

        raise 'app must be set' unless @app
        define
      end

      def yapp_env
        @yapp_env ||= (ENV['YAPP_ENV'] || 'dev')
      end

      def define
        generate_index_task = task name, :manifest_id do |t, args|
          manifest_id = args[:manifest_id] || yapp_env
          generator = Embarista::DynamicIndex::Generator.generator(erb_path, manifest_id)
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
