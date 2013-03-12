require 'rake'
require 'rake/tasklib'

module Embarista
  class AssetsTask < ::Rake::TaskLib
    attr_accessor :name, :app, :assets_bucket

    def initialize(name = :assets)
      @name = name

      yield self if block_given?

      @assets_bucket ||= App.assets_bucket

      raise 'app must be set' unless @app
      define
    end

    private
    def define
      assets_task = task name, :manifest_id do |t, args|
        manifest_id = args[:manifest_id] || App.latest_manifest_id

        raise "assets distro not found for ID #{manifest_id}" unless File.exist? "tmp/public/#{manifest_id}.yml"

        Embarista::S3sync.sync('tmp/public',
          bucket_name: assets_bucket,
          local_manifest_path: "#{manifest_id}.yml",
          remote_manifest_path: "#{app}-manifest-latest.yml",
        )
        puts generate_index_command(t, manifest_id)
      end
      assets_task.add_description "deploy assets to S3"
    end

    def generate_index_command(task, manifest_id)
      generate_index_task_name = ::Rake::Task.scope_name(task.scope, 'generate_index')
      "#{App.env_var}=qa|prod be rake \"#{generate_index_task_name}[#{manifest_id}]\""
    end
  end
end
