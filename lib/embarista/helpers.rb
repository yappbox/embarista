module Embarista
  module Helpers
    def rewrite_manifest_urls(*args, &block)
      filter(Embarista::Filters::ManifestUrlFilter, *args, &block)
    end

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

    def sass_uncompressed(options={}, &block)
      options[:additional_load_paths] ||= 'css'
      options[:style] = :expanded
      options[:line_comments] = true
      sass(options, &block)
    end

    def sass_compressed(options={}, &block)
      options[:additional_load_paths] ||= 'css'
      options[:style] = :compressed
      options[:line_comments] = false
      sass(options, &block)
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

