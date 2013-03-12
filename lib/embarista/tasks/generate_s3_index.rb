require 'rake'
require 'rake/tasklib'

module Embarista
  class GenerateS3IndexTask < ::Rake::TaskLib
    attr_accessor :name, :erb_path, :app, :assets_bucket

    def initialize(name = :generate_s3_index)
      @name = name
      @erb_path = "app/index.html.erb"

      yield self if block_given?

      @assets_bucket ||= App.assets_bucket

      raise 'app must be set' unless @app
      define
    end

    private
    def define
      generate_s3_index_task = task name, :manifest_id do |t, args|
        manifest_id = args[:manifest_id] || App.latest_manifest_id
        generator = DynamicIndex::Generator.generator(erb_path, manifest_id, "//s3.amazonaws.com/#{assets_bucket}")
        io = StringIO.new(generator.html)

        s3 = S3.new(assets_bucket)
        s3.store("#{app}/index-#{App.env}.html", io)
      end
      generate_s3_index_task.add_description "Generate a index for the app and deploy it to S3"
    end
  end
end
