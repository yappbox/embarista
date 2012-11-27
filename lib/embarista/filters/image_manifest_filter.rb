module Embarista
  module Filters
    class ImageManifestFilter < Rake::Pipeline::Filter
      def generate_output(inputs, output)
        inputs.each do |input|
          manifest_json = input.read
          output.write("var IMAGES_MANIFEST = #{manifest_json};")
        end
      end
    end
  end
end
