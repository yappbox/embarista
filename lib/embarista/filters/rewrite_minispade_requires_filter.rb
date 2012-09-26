module Embarista
  module Filters
    class RewriteMinispadeRequiresFilter < Rake::Pipeline::Filter
      attr_reader :options

      def initialize(options, &block)
        @options = options || {}
        @options[:prefix] = '' unless @options.has_key?(:prefix)
        super(&block)
      end

      def generate_output(inputs, output)
        inputs.each do |input|
          code = input.read
          #puts input.path
          relative_root = Pathname.new(input.path).dirname
          code.gsub!(%r{\brequire(All)?\s*\(\s*(["'/])([^"']+)\2\s*}) do |m|
            optional_all = $1
            quote_char = $2
            before_path = $3
            path = before_path.dup
            path = relative_root.join(path).to_s if path.start_with?('.')
            path.gsub!(%r{^#{options[:root]}/}, options[:prefix]) if options[:root]
            #puts "require#{optional_all}: #{before_path} -> #{path}"
            "minispade.require#{optional_all}(#{quote_char}#{path}#{quote_char}"
          end
          output.write(code)
        end
      end
    end
  end
end
