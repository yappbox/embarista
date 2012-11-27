require "rake-pipeline-web-filters"

module Embarista
  module Filters
    autoload :ErbFilter,                      'embarista/filters/erb_filter'
    autoload :ManifestUrlFilter,              'embarista/filters/manifest_url_filter'
    autoload :PrecompileHandlebarsFilter,     'embarista/filters/precompile_handlebars_filter'
    autoload :RewriteMinispadeRequiresFilter, 'embarista/filters/rewrite_minispade_requires_filter'
    autoload :StripEmberAssertsFilter,        'embarista/filters/strip_ember_asserts_filter'
  end
end
