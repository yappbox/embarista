module Embarista
  module Filters
    class MakeModuleFilter < Rake::Pipeline::Filter
      attr_reader :options

      def initialize(options= {}, &block)
        @options = options
        super(&block)
        unless block_given?
          @output_name_generator = proc { |input| input.sub(/\.js$/, '') }
        end
      end

      def generate_output(inputs, output)
        if @options[:es6]
          es6_module_filter = Rake::Pipeline::Web::Filters::ES6ModuleFilter.new(@options)
          es6_module_filter.generate_output(inputs, output)
        else
          minispade_filter = Rake::Pipeline::Web::Filters::MinispadeFilter.new(@options)
          minispade_filter.generate_output(inputs, output)
        end
      end

      private
      def external_dependencies
        [ 'ruby_es6_module_transpiler' ]
      end
    end
  end
end
