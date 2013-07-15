module Embarista
  module Filters
    class RewriteMinispadeRequiresFilter < Rake::Pipeline::Filter
      attr_reader :options

      def initialize(options=nil, &block)
        @options = options || {}
        @options[:prefix] = '' unless @options.has_key?(:prefix)
        super(&block)
      end

      def generate_output(inputs, output)
        inputs.each do |input|
          code = input.read
          #puts input.path
          relative_root = Pathname.new(input.path).dirname
          code.gsub!(%r{(?<!\.)\brequire\s*\(\s*["']([^"']+)["']\s*}) do |m|
            before_path = $1
            path = before_path.dup
            path = relative_root.join(path).to_s if path.start_with?('.')
            path = path.gsub(%r{^#{options[:root]}/}, '') if options[:root]
            path = options[:prefix] + path if options[:prefix] && !path.include?(':')
            # puts "require: #{before_path} -> #{path}"
            "minispade.require('#{path}'"
          end
          code.gsub!(%r{(?<!\.)\brequireAll\s*\(([^)]+)\)}) do |m|
            regex = $1
            # puts "requireAll: #{regex}"
            "minispade.requireAll(#{regex})"
          end
          output.write(code)
        end
      end
    end
  end
end
