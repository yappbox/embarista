module Embarista
  module DynamicIndex
    class Generator
      attr_reader :erb_path, :context

      def initialize(erb_path, context)
        @erb_path = erb_path
        @context = context
      end

      def html
        File.open(erb_path, 'r:UTF-8') do |f|
          erb = ERB.new(f.read, nil, '-')
          erb.filename = erb_path
          context.instance_eval do
            erb.result(binding)
          end
        end
      end

      def self.generator(erb_path, manifest_id, assets_base_url=App.assets_base_url)
        context = Context.context(manifest_id, assets_base_url)
        self.new(erb_path, context)
      end
    end
  end
end
