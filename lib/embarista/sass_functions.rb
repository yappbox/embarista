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
      return path unless use_manifest?
      manifest[path.value] or path
    end

    def use_manifest?
      ENV.key?('RAKEP_DIGEST')
    end
  end
end
