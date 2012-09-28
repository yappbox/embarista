module Embarista
  module Helpers
    def precompile_handlebars(*args, &block)
      filter(Embarista::Filters::PrecompileHandlebarsFilter, *args, &block)
    end

    def rewrite_minispade_requires(*args, &block)
      filter(Embarista::Filters::RewriteMinispadeRequiresFilter, *args, &block)
    end

    def erb(*args, &block)
      filter(Embarista::Filters::ErbFilter, *args, &block)
    end

    def strip_ember_asserts(*args, &block)
      filter(Embarista::Filters::StripEmberAssertsFilter, *args, &block)
    end

    def concat_file_list(file_list, output_filenames)
      match "{#{file_list.join(',')}}" do
        concat(file_list) { Array(output_filenames) }
      end
    end

    def tee(extension_regexp, second_extension)
      concat {|path| [path, path.gsub(extension_regexp, second_extension)] }
    end

    def process_javascript(pattern, opts)
      match pattern, &JavascriptPipeline.new(opts)
    end

    def sass_uncompressed(&block)
      sass(:additional_load_paths => 'css',
           :style => :expanded,
           :line_comments => true,
           &block)
    end

    def sass_compressed(&block)
      sass(:additional_load_paths => 'css',
           :style => :compressed,
           :line_comments => false,
           &block)
    end

    # rename "qunit-*.css" => "qunit.css"
    def rename(renames_map)
      renames_map.each do |pattern, output_filename|
        match pattern do
          concat output_filename
        end
      end
    end
  end
end

