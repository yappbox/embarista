module Embarista
  module Filters
    class PrecompileHandlebarsFilter < Rake::Pipeline::Filter
      def initialize(options={}, &block)
        @template_dir = options[:template_dir] || 'templates'
        @templates_global = options[:templates_global] || 'Ember.TEMPLATES'
        @es6 = options[:es6]

        options[:handlebars] ||= default_handlebars_src
        options[:ember_template_compiler] ||= default_ember_template_compiler_src

        throw Embarista::PrecompilerConfigurationError.new('Must specify handlebars source path') unless options[:handlebars]
        throw Embarista::PrecompilerConfigurationError.new('Must specify ember_template_compiler source path') unless options[:ember_template_compiler]
        @handlebars_src = options[:handlebars]
        @ember_template_compiler_src = options[:ember_template_compiler]

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
          compiled = precompile(input.read, @handlebars_src, @ember_template_compiler_src)

          if @es6
            output.write "\nexport default #{compiled};\n"
          else
            output.write "\n#{@templates_global}['#{full_name}'] = #{compiled};\n"
          end
        end
      end

      def default_handlebars_src
        Dir['app/vendor/handlebars-*'].last
      end

      def default_ember_template_compiler_src
        Dir['app/vendor/ember-template-compiler-*.js'].last
      end

    private

      def precompile(template_string, handlebars_src, ember_template_compiler_src)
        precompiler = Embarista::Precompiler.new(
          :handlebars => handlebars_src,
          :ember_template_compiler => ember_template_compiler_src
        )
        compiled = precompiler.compile(template_string)
        js = "Ember.Handlebars.template(#{compiled})"
        "#{js};"
      end
    end
  end
end
