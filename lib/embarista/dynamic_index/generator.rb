module Embarista
  module DynamicIndex
    class Generator
      attr_reader :erb_path, :context, :app_base_url

      def initialize(erb_path, context, app_base_url)
        @erb_path = erb_path
        @context = context
        @app_base_url = app_base_url
      end

      def html
        File.open(erb_path, 'r:UTF-8:UTF-8') do |f|
          erb = ERB.new(f.read, nil, '-')
          erb.filename = erb_path
          context.instance_eval do
            erb.result(binding)
          end
        end
      end

      def preview_url(app)
        "#{app_base_url}/#{app}/?manifest_id=#{context.manifest_id}"
      end

      def self.generator(erb_path, manifest_id)
        context = Context.context(manifest_id)
        app_base_url = App.app_base_url
        self.new(erb_path, context, app_base_url)
      end
    end
  end
end
