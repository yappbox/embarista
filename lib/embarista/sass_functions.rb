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
      @_manifest ||= begin
        # TODO: some switch so that this doesn't run in dev?
        manifest_path = 'public/manifest.yml'
        return {} unless File.exist?(manifest_path)
        YAML.load_file(manifest_path)
      end
    end

    def lookup_manifest_path(path)
      if digest?
        raise ::Sass::SyntaxError.new "manifest-url(#{path.inspect}) missing manifest entry" unless manifest.key? path
        manifest[path]
      else
        path
      end
    end

    def digest?
      ENV.key?('RAKEP_DIGEST')
    end
  end
end
