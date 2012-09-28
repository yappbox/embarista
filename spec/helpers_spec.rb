require 'spec_helper'

describe Embarista::Helpers do
  let(:pipeline) { Rake::Pipeline.new }
  let(:dsl) { Rake::Pipeline::DSL::PipelineDSL.new(pipeline) }

  describe '#rewrite_minispade_requires' do
    it 'creates a Embarista::Filters::RewriteMinispadeRequiresFilter' do
      dsl.rewrite_minispade_requires
      pipeline.filters.last.should be_kind_of(Embarista::Filters::RewriteMinispadeRequiresFilter)
    end
  end
end
