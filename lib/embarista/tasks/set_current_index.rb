require 'rake'
require 'rake/tasklib'

module Embarista
  class SetCurrentIndexTask < ::Rake::TaskLib
    attr_accessor :name, :app, :redis

    def initialize(name = :set_current_index)
      @name = name

      yield self if block_given?

      @redis ||= Redis.client

      raise 'app must be set' unless @app
      define
    end

    private
    def define
      set_current_task = task name, :manifest_id do |t, args|
        manifest_id = args[:manifest_id] || App.env.to_s

        puts "redis.set('#{app}:index:current', '#{manifest_id}')"
        redis.set("#{app}:index:current", manifest_id)
      end
      set_current_task.add_description "Activates a manifest in the given #{App.env_var}"
    end
  end
end
