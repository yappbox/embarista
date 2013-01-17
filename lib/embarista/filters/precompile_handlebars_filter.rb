require 'barber'

module Embarista
  module Filters
    class PrecompileHandlebarsFilter < Rake::Pipeline::Filter
      def initialize(options= {}, &block)
        @template_dir = options[:template_dir] || 'templates'

        super(&block)
        unless block_given?
          @output_name_generator = proc { |input| input.sub(/\.handlebars$/, '.js') }
        end
      end


      def generate_output(inputs, output)
        inputs.each do |input|
          name = File.basename(input.path, '.handlebars')
          dirname = File.dirname(input.path)

          dirname.gsub!(/^\/?#{@template_dir}\/?/,'')

          full_name = [dirname, name].compact.reject(&:empty?).join('/')
          compiled = Barber::Ember::FilePrecompiler.call(input.read)

          output.write "\nEmber.TEMPLATES['#{full_name}'] = #{compiled};\n"
        end
      end
    end
  end
end
