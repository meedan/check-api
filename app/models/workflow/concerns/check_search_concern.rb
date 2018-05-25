module Workflow
  module Concerns
    module CheckSearchConcern
      CheckSearch.class_eval do
        def status_search_fields
          ::Workflow::Workflow.workflow_ids
        end
      end
    end
  end
end
