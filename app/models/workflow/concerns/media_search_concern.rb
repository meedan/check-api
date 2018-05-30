module Workflow
  module Concerns
    module MediaSearchConcern
      MediaSearch.class_eval do
        ::Workflow::Workflow.workflow_ids.each do |id|
          attribute id.to_sym, String
        end
      end
    end
  end
end
