# Abstract class for create or update mutations
class BaseUpdateOrCreateMutation < GraphQL::Schema::RelayClassicMutation
  argument :id, ID, required: false

  class << self
    # For use in subclasses
    def define_create_behavior(subclass, mutation_target, parents)
      # subclass.argument :id, ID, required: false

      define_shared_behavior(:create, subclass, mutation_target, parents)
    end

    # For use in subclasses
    def define_update_behavior(subclass, mutation_target, parents)
      # subclass.argument :id, ID, required: true

      define_shared_behavior(:update, subclass, mutation_target, parents)
    end

    private

    # This method needs to be called after the subclass is initially loaded. Unfortunately,
    # this means that we can't use the self.inherited callback, because the callback is executed
    # on inheritance and the properties of the subclass (like class methods self.type and self.parents
    # aren't yet available.
    #
    # Because of this, we have to manually call this method in every class we want the behavior to
    # appear in. I hope there's a better way
    def define_shared_behavior(action, subclass, mutation_target, parents)
      subclass.graphql_name "#{action.to_s.camelize}#{mutation_target.to_s.camelize}"

      type_class = "#{mutation_target.to_s.camelize}Type".constantize
      subclass.field mutation_target, type_class, null: true
      subclass.field "#{type_class}Edge", type_class.edge_type, null: true

      parents.each do |parent_field|
        subclass.field parent_field.to_sym, "#{parent_field.camelize}Type", null: true
      end

      subclass.class_eval <<~METHOD
        def resolve(**inputs)
          pp "IN PARENT RESOLVE", inputs, context
          obj = GraphqlCrudOperations.object_from_id_and_context(inputs[:id], context)
          return unless inputs[:id] || obj

          GraphqlCrudOperations.update_from_single_id(inputs[:id] || obj.graphql_id, inputs, context, #{parents})
        end
      METHOD
    end
  end
end
