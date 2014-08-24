require 'rake'
require 'rake/tasklib'

module Embarista
  class UploadIndexTask < ::Rake::TaskLib
    attr_accessor :name, :erb_path, :app, :redis

    def initialize(name = :upload_index)
      @name = name
      @html_path = "dist/index.html"

      yield self if block_given?

      @redis ||= Redis.client

      raise 'app must be set' unless @app
      define
    end

    private
    def define
      generate_index_task = task name, :manifest_id do |t, args|
        manifest_id = args[:manifest_id] || App.env.to_s
        html = File.read(@html_path)

        puts "redis.set('#{app}:index:#{manifest_id}', '#{html[0,10].strip}...')"

        redis.set("#{app}:index:#{manifest_id}", html)

        puts "To preview: #{preview_url(app, manifest_id)}"
        puts "To activate: #{set_current_command(t, manifest_id)}"
      end
      generate_index_task.add_description "Upload index file at dist/index.html to redis, run once with dev to boostrap environment"
    end

    def preview_url(app, manifest_id)
      "#{App.app_base_url}/#{app}/?manifest_id=#{manifest_id}"
    end

    def set_current_command(task, manifest_id)
      set_current_task_name = ::Rake::Task.scope_name(task.scope, 'set_current_index')
      "#{App.env_var}=#{App.env} rake \"#{set_current_task_name}[#{manifest_id}]\""
    end
  end
end
