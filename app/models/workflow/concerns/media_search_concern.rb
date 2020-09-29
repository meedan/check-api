module Workflow
  module Concerns
    module MediaSearchConcern
      MediaSearch.class_eval do
        ::Workflow::Workflow.workflow_ids.each do |id|
          mapping do
            indexes id.to_sym, { type: 'keyword' }
          end
        end
      end
    end
  end
end
