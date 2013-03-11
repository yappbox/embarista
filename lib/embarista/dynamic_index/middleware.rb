module Embarista
  module DynamicIndex
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
  end
end
