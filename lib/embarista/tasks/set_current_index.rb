require 'rake'
require 'rake/tasklib'

module Embarista
  class SetCurrentIndexTask < ::Rake::TaskLib
    attr_accessor :name, :app, :key, :redis

    def initialize(name = :set_current_index, key = 'index')
      @name = name
      @key = key

      yield self if block_given?

      @redis ||= Redis.client

      raise 'app must be set' unless @app
      define
    end

    private
    def define
      set_current_task = task(name, :manifest_id) do |t, args|
        manifest_id = args[:manifest_id] || App.env.to_s

        manifest_key = prefix(manifest_id)
        unless redis.exists(manifest_key)
          raise "manifest key '#{manifest_key}' does not exist"
        end

        current_key = prefix('current')
        previous_key = prefix('previous')

        current_id = redis.get(current_key)
        if current_id
          puts "setting #{current_key} to #{manifest_id} from #{current_id}"
          redis.lpush(previous_key, previous_id)
          redis.set(current_key, manifest_id)
        else
          puts "setting #{current_key} to #{manifest_id}"
          redis.set(current_key, manifest_id)
        end
      end
      set_current_task.add_description "Activates a manifest in the given #{App.env_var}"
    end

    def prefix(id)
      "#{app}:#{key}:#{id}"
    end
  end
end
