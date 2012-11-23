module Embarista
  module SassFunctions
    def manifest_url(path)
      Sass::Script::String.new("url(#{lookup_manifest_path(path)})")
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
        manifest.fetch(path.value)
      else
        path
      end
    end

    def digest?
      ENV.key?('RAKEP_DIGEST')
    end
  end
end
