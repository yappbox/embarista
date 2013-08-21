require 'execjs'
require 'json'

module Embarista

  class PrecompilerError < StandardError
    def initialize(template, error)
      @template, @error = template, error
    end

    def to_s
      "Pre-compilation failed for: #{@template}\n. Compiler said: #{@error}"
    end
  end

  class PrecompilerConfigurationError < StandardError
    def initialize(message)
      @message = message
    end

    def to_s
      @message
    end
  end

  class Precompiler
    def initialize(opts)
      throw PrecompilerConfigurationError.new('Must specify handlebars source path') unless opts[:handlebars]
      throw PrecompilerConfigurationError.new('Must specify ember_template_compiler source path') unless opts[:ember_template_compiler]
      @handlebars = File.new(opts[:handlebars])
      @ember_template_precompiler = File.new(opts[:ember_template_compiler])
    end

    def compile(template)
      context.call(
        "EmberHandlebarsCompiler.precompile",
        sanitize(template)
      )
    rescue ExecJS::ProgramError => ex
      raise Embarista::PrecompilerError.new(template, ex)
    end

    def sources
      [precompiler, handlebars, ember_template_precompiler]
    end

    attr_reader :handlebars, :ember_template_precompiler

    def precompiler
      @precompiler ||= StringIO.new(<<-JS)
        var exports = this.exports || {};
        function require() {
          // ember-template-compiler only requires('handlebars')
          return Handlebars;
        }
        // Precompiler
        var EmberHandlebarsCompiler = {
          precompile: function(string) {
            return exports.precompile(string).toString();
          }
        };
      JS
    end


  private

    def sanitize(template)
      begin
        JSON.load(%Q|{"template":#{template}}|)['template']
      rescue JSON::ParserError
        template
      end
    end

    def context
      @context ||= ExecJS.compile(source)
    end

    def source
      @source ||= sources.map(&:read).join("\n;\n")
    end
  end
end
