module Embarista
  module Filters
    class PrecompileHandlebarsFilter < Rake::Pipeline::Filter 
      class << self
        def emberjs_path=(path)
          if defined?(@@emberjs_path)
            raise "Cannot set emberjs_path to #{path}. It was already set to #{@@emberjs_path}"
          else
            @@emberjs_path = path
          end
        end

        def handlebarsjs_path=(path)
          if defined?(@@handlebarsjs_path)
            raise "Cannot set handlebarsjs_path to #{path}. It was already set to #{@@handlebarsjs_path}"
          else
            @@handlebarsjs_path = path
          end
        end

        def jquery_version=(jquery_version)
          @@jquery_version = jquery_version
        end

        def headless_ember_preamble
          <<-JS
            // DOM
            var Element = {};
            Element.firstChild = function () { return Element; };
            Element.innerHTML = function () { return Element; };

            var document = { createRange: false, createElement: function() { return Element; } };
            var window = this;
            this.document = document;

            // Console
            var console = window.console = {};
            console.log = console.info = console.warn = console.error = function(){};

            // jQuery
            var jQuery = window.jQuery = function() { return jQuery; };
            jQuery.ready = function() { return jQuery; };
            jQuery.inArray = function() { return jQuery; };
            jQuery.jquery = "#{@@jquery_version}";
            jQuery.event = { fixHooks: {} };
            var $ = jQuery;

            // Ember
            function precompileEmberHandlebars(string) {
              return Ember.Handlebars.precompile(string).toString();
            }
          JS
        end

        def contents
          raise "Must set emberjs_path" unless @@emberjs_path
          raise "Must set handlebarsjs_path" unless @@handlebarsjs_path
          raise "Must set jquery_version" unless @@jquery_version
          @@contents ||= [File.read(@@handlebarsjs_path),
                          headless_ember_preamble,
                          File.read(@@emberjs_path)].join("\n")
        end

        def context
          @@context ||= ExecJS.compile(contents)
        end
      end

      def initialize(options= {}, &block)
        @options = options
        self.class.emberjs_path = options[:emberjs]
        self.class.handlebarsjs_path = options[:handlebarsjs]
        self.class.jquery_version = options[:jquery_version]

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

          compiled = self.class.context.call("precompileEmberHandlebars", input.read)
          output.write "\nEmber.TEMPLATES['#{full_name}'] = Ember.Handlebars.template(#{compiled});\n"
        end
      end

      private
      def external_dependencies
        [ 'execjs' ]
      end
    end
  end
end
