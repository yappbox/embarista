module Embarista
  module Filters
    class StripEmberAssertsFilter < Rake::Pipeline::Filter
      def generate_output(inputs, output)
        inputs.each do |input|
          result = input.read
          result.gsub!(/Em(?:ber)?\.(assert|warn|deprecate|deprecateFunc)\((.*)\);/, '')
          output.write(result)
        end
      end
    end
  end
end
