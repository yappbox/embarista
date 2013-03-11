module Embarista
  module DynamicIndex
    class Context
      attr_reader :app_config, :manifest_id, :manifest, :assets_base_url

      def initialize(app_config, manifest_id, manifest, assets_base_url)
        @app_config = app_config
        @manifest_id = manifest_id
        @manifest = manifest
        @assets_base_url = assets_base_url
      end

      def manifest_url(source)
        source = manifest[source] || source
        assets_base_url + source
      end

      def self.context(manifest_id=nil)
        manifest_id ||= App.env.to_s
        manifest = load_manifest(manifest_id)
        self.new(App.config, manifest_id, manifest, App.assets_base_url)
      end

      def self.load_manifest(manifest_id)
        if manifest_id == 'dev'
          {}
        else
          YAML.load_file("tmp/public/#{manifest_id}.yml")
        end
      end
    end
  end
end
