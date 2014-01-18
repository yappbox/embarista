module Embarista
  class JavascriptPipeline
    def initialize(options)
      @options = options
    end

    def to_proc
      options = @options
      @options[:prefix] = '' unless @options.has_key?(:prefix)
      Proc.new do
        module_id_generator = proc {|input|
          module_id = input.path.sub(/\.js(\.dev|\.prod)?$/, '')
          module_id.gsub!(%r{^#{options[:root]}/}, options[:prefix]) if options[:root]
          # puts input.path
          # puts "module_id: #{module_id}"
          module_id
        }
        unless options[:es6]
          rewrite_minispade_requires(root: options[:root], prefix: options[:prefix])
        end
        concat { |path| ["#{path}.prod", "#{path}.dev"] }
        match "**/*.js.prod" do
          strip_ember_asserts
          make_module(string: true, module_id_generator: module_id_generator, es6: options[:es6])
          uglify(copyright: false) {|input| input}
          concat { Array(options[:concat]).map{|path| path.gsub(/\.js$/, '.min.js')} }
        end
        match "**/*.js.dev" do
          make_module(module_id_generator: module_id_generator, es6: options[:es6])
          concat { Array(options[:concat]) }
        end
      end
    end
  end
end
