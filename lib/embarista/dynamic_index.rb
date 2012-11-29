require 'rake'
require 'rake/tasklib'

module Embarista
  module DynamicIndex
    class Generator
      attr_reader :env_config, :yapp_env, :manifest_id, :yapp_config

      def initialize(erb_path, manifest_id)
        @erb_path = erb_path
        @env_config = Yapp.load_config
        @yapp_env = ENV.fetch('YAPP_ENV').to_sym
        @yapp_config = env_config.fetch(yapp_env)
        @manifest_id = manifest_id
        prepare_manifest
      end

      def prepare_manifest
        if @manifest_id == 'dev'
          @manifest = {}
        else
          #TODO: ensure the manifest is on s3
          @manifest = YAML.load_file("tmp/public/#{@manifest_id}.yml")
        end
      end

      def manifest_url(source)
        source = @manifest[source] || source
        "//#{yapp_config.domains.assets_cdn}#{source}"
      end

      def html
        File.open(@erb_path) do |f|
          erb = ERB.new(f.read, nil, '-')
          erb.result(binding)
        end
      end
    end

    class Middleware
      def initialize(app, opts = {})
        @app = app
        @erb_path = opts[:erb] || 'app/index.html.erb'
        @path_info = opts.fetch(:path_info)
        @generator = Embarista::DynamicIndex::Generator.new(@erb_path, 'dev')
      end

      def call(env)
        path = env["PATH_INFO"]
        if path == @path_info
          [
            200,
            { 'Content-Type' => "text/html" },
            [ @generator.html ]
          ]
        else
          @app.call(env)
        end
      end
    end

    class Task < ::Rake::TaskLib
      attr_accessor :name, :erb_path, :output_dir

      def initialize(name = :generate_index)
        @name = name
        @erb_path = "app/index.html.erb"
        @output_dir = "tmp"
        yield self if block_given?
        define
      end

      def define
        task name, :manifest_id do |t, args|
          manifest_id = args[:manifest_id]
          mkdir_p output_dir
          File.open("#{output_dir}/index.html", "w") do |f|
            generator = Embarista::DynamicIndex::Generator.new(erb_path, manifest_id)
            f.write(generator.html)
          end
        end
      end
    end

  end
end
