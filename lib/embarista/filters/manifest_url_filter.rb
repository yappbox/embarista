module Embarista
  module Filters
    class ManifestUrlFilter < Rake::Pipeline::Filter
      attr_reader :options

      def initialize(options= {}, &block)
        @options = options || {}
        raise 'Must pass :path option' unless @options.key?(:path)
        super(&block)
      end

      attr_writer :urls_manifest
      def urls_manifest
        @urls_manifest ||= begin
          if File.exists?(options[:path])
            JSON.parse(IO.read(options[:path]))
          else
            {}
          end
        end
      end

      def generate_output(inputs, output)
        inputs.each do |input|
          code = input.read
          code.gsub!(%r{\bmanifest_url\(\s*(["'/])([^"']+)\1\)}) do |m|
            quote_char = $1
            path = $2

            # take the anchor/querystring off if there is one
            post_path_start = path.index(/[?#]/)
            if post_path_start
              post_path = path[post_path_start..-1]
              path = path[0..post_path_start-1]
            end

            path = "/#{path}" unless path =~ %r{^/}
            path = "#{options[:prefix]}#{path}"
            resolved_path = urls_manifest[path] || path

            # put the anchor/querystring back on, if there is one
            resolved_path = resolved_path + post_path if post_path

            "(#{options[:prepend]}'#{resolved_path}')"
          end
          output.write(code)
        end
      end
    end
  end
end
