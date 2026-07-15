module Loaders
  class FirstResponseLoader < GraphQL::Batch::Loader
    def perform(task_ids)
      responses = Annotation
        .where(
          annotated_type: 'Task',
          annotated_id: task_ids
        )
        .where("annotation_type LIKE 'task_response%'")
        .order(:created_at)
        .group_by(&:annotated_id)

      task_ids.each do |id|
        fulfill(id, responses[id]&.first)
      end
    end
  end
end
