require 'rake-pipeline'

module Embarista
  autoload :Helpers, 'embarista/helpers'
  autoload :Filters, 'embarista/filters'
  autoload :Version, 'embarista/version'

  autoload :JavascriptPipeline, 'embarista/javascript_pipeline'
end

Rake::Pipeline::DSL::PipelineDSL.send(:include, Embarista::Helpers)
