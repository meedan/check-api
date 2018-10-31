module Workflow
  module Concerns
    module GraphqlCrudOperationsConcern
      GraphqlCrudOperations.class_eval do
        singleton_class.send(:alias_method, :define_default_type_original, :define_default_type)

        def self.define_field_for_team_statuses
          proc do |id|
            field id.pluralize.to_sym, JsonStringType do
              resolve -> (obj, _args, _ctx) {
                team = Team.current || Team.new
                type = 'media'
                type = 'source' if obj.is_a?(Source)
                team.send(id.pluralize, type, obj) unless type.nil?
              }
            end
          end
        end

        def self.define_field_for_object_statuses
          proc do |id, type|
            field "#{type}_#{id.pluralize}".to_sym, JsonStringType do
              resolve -> (obj, _args, _ctx) {
                obj.send(id.pluralize, type) if obj.is_a?(Team)
              }
            end
          end
        end

        def self.define_default_type(&block)
          GraphqlCrudOperations.define_default_type_original do
            ::Workflow::Workflow.workflows.each do |workflow|
              next if workflow.target != ProjectMedia
              id = workflow.id

              ['media', 'source'].each do |type|
                instance_exec id, type, &GraphqlCrudOperations.define_field_for_object_statuses
              end

              instance_exec id, &GraphqlCrudOperations.define_field_for_team_statuses
            end

            instance_eval(&block)
          end
        end
      end
    end
  end
end
