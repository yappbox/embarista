module Embarista
  module Filters
    class ErbFilter < Rake::Pipeline::Filter
      attr_reader :options

      def initialize(options= {}, &block)
        @options = options
        super(&block)
        unless block_given?
          @output_name_generator = proc { |input| input.sub(/\.erb$/, '') }
        end
      end

      def generate_output(inputs, output)
        inputs.each do |input|
          erb = ERB.new(input.read, nil, '-')
          binding = @options[:binding]
          output.write erb.result(binding)
        end
      end

      private
      def external_dependencies
        [ 'erb' ]
      end
    end
  end
end
