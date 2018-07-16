module Workflow
  module Concerns
    module MediaSearchConcern
      MediaSearch.class_eval do
        ::Workflow::Workflow.workflow_ids.each do |id|
          attribute id.to_sym, String, mapping: { type: 'keyword' }
        end
      end
    end
  end
end
