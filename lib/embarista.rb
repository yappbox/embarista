require 'rake-pipeline'

module Embarista
  autoload :Helpers, 'embarista/helpers'
  autoload :Filters, 'embarista/filters'
  autoload :Version, 'embarista/version'

  autoload :JavascriptPipeline, 'embarista/javascript_pipeline'
  autoload :Server, 'embarista/server'

  autoload :Git,          'embarista/git'
  autoload :S3sync,       'embarista/s3sync'
  autoload :DigestHelper, 'embarista/digest_helper'
  autoload :ManifestHelper, 'embarista/manifest_helper'
  autoload :SassFunctions,  'embarista/sass_functions'
end

Rake::Pipeline::DSL::PipelineDSL.send(:include, Embarista::Helpers)
