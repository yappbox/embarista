require 'rake-pipeline'

module Embarista
  autoload :Helpers, 'embarista/helpers'
  autoload :Filters, 'embarista/filters'
  autoload :Version, 'embarista/version'

  autoload :JavascriptPipeline, 'embarista/javascript_pipeline'
  autoload :Server, 'embarista/server'

  autoload :App,             'embarista/app'
  autoload :Git,             'embarista/git'
  autoload :Redis,           'embarista/redis'
  autoload :S3,              'embarista/s3'
  autoload :S3sync,          'embarista/s3sync'
  autoload :SassFunctions,   'embarista/sass_functions'
  autoload :ManifestBuilder, 'embarista/manifest_builder'
  autoload :DynamicIndex,    'embarista/dynamic_index'
end

Rake::Pipeline::DSL::PipelineDSL.send(:include, Embarista::Helpers)
