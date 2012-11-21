module Embarista
  module ManifestHelper
    extend self

    def prefix_manifest(prefix, manifest)
      manifest.each_with_object({}) do |entry, new_manifest|
        key = prefix + entry.first
        value = prefix + entry.last

        new_manifest[key] = value
      end
    end
  end
end
