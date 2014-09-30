module Embarista
  module SassFunctions
    def manifest_url(path)
      digested_path = lookup_manifest_path(path.value)
      Sass::Script::String.new("url(#{digested_path})")
    end

    def manifest_path(path)
      digested_path = lookup_manifest_path(path.value)
      Sass::Script::String.new(digested_path)
    end

  private

    def manifest
      @@_manifest ||= begin
        # TODO: some switch so that this doesn't run in dev?
        manifest_path = 'public/manifest.yml'
        return {} unless File.exist?(manifest_path)
        YAML.load_file(manifest_path)
      end
    end

    def lookup_manifest_path(path)
      # take the anchor/querystring off if there is one
      post_path_start = path.index(/[?#]/)
      if post_path_start
        post_path = path[post_path_start..-1]
        path = path[0..post_path_start-1]
      end

      resolved_path = if digest?
                        raise ::Sass::SyntaxError.new "manifest-url(#{path.inspect}) missing manifest entry" unless manifest.key? path
                        manifest[path]
                      else
                        path
                      end

      # put the anchor/querystring back on, if there is one
      "#{resolved_path}#{post_path}"
    end

    def digest?
      ENV.key?('RAKEP_DIGEST')
    end
  end
end
