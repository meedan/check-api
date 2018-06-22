module Workflow
  module Concerns
    module MediaSearchConcern
      MediaSearch.class_eval do
        ::Workflow::Workflow.workflow_ids.each do |id|
          attribute id.to_sym, String, mapping: { index: 'not_analyzed' }
        end
      end
    end
  end
end
