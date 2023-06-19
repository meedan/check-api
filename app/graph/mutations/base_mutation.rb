class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class << self
    def define_create_behavior(subclass, mutation_target, parents)
      define_create_or_update_behavior('create', subclass, mutation_target, parents)
    end

    def define_update_behavior(subclass, mutation_target, parents)
      subclass.argument :id, GraphQL::Types::ID, required: true

      define_create_or_update_behavior('update', subclass, mutation_target, parents)
    end

    def define_destroy_behavior(subclass, mutation_target, parents)
      subclass.graphql_name "Destroy#{mutation_target.to_s.camelize}"

      subclass.argument :id, GraphQL::Types::ID, required: true
      subclass.field :deletedId, GraphQL::Types::ID, null: true

      type_class = "#{mutation_target.to_s.camelize}Type".constantize
      subclass.field mutation_target, type_class, camelize: false, null: true
      subclass.field "#{type_class}Edge", type_class.edge_type, null: true

      parents.each do |parent_field|
        subclass.field parent_field.to_sym, "#{parent_field.camelize}Type", null: true
      end

      subclass.define_method :resolve do |**inputs|
        ::GraphqlCrudOperations.destroy(inputs, context, parents)
      end

      # HANDLE IN CLASS
      # input_field(:keep_completed_tasks, types.Boolean) if type == "team_task"

      # HANDLE IN CLASS
      # if type == "relationship"
      #   input_field(:add_to_project_id, types.Int)
      #   input_field(:archive_target, types.Int)
      # end

      # HANDLE IN CLASS
      # input_field(:items_destination_project_id, types.Int) if type == "project"
    end

    private

    # This method needs to be called after the subclass is initially loaded. Unfortunately,
    # this means that we can't use the self.inherited callback, because the callback is executed
    # on inheritance and the properties of the subclass (like constants or class methods aren't yet available.
    #
    # Because of this, we have to manually call this method in every class we want the behavior to
    # appear in. I hope there's a better way; brain's not finding it right now
    def define_create_or_update_behavior(action, subclass, mutation_target, parents)
      subclass.graphql_name "#{action.camelize}#{mutation_target.camelize}"

      type_class = "#{mutation_target.camelize}Type".constantize
      subclass.field mutation_target, type_class, null: true
      subclass.field "#{type_class}Edge", type_class.edge_type, null: true

      # NEED TO FIGURE OUT WHAT TO DO WITH THIS
      # GraphqlCrudOperations.define_parent_returns(parents).each{ |field_name, field_class| return_field(field_name, field_class) }
      # def parent_type_returns(parents)
        # fields = {}
        # parents.each do |parent|
        #   parentclass = parent =~ /^check_search_/ ? 'CheckSearch' : parent.gsub(/_was$/, '').camelize
        #   parentclass = 'ProjectMedia' if ['related_to', 'source_project_media', 'target_project_media'].include?(parent)
        #   parentclass = 'TagText' if parent == 'tag_text_object'
        #   parentclass = 'Project' if parent == 'previous_default_project'
        #   fields[parent.to_sym] = "#{parentclass}Type".constantize
        # end
        # fields
      # end
      parents.each do |parent_field|
        subclass.field parent_field.to_sym, "#{parent_field.camelize}Type", null: true
      end

      subclass.define_method :resolve do |**inputs|
        ::GraphqlCrudOperations.public_send(action, mutation_target, inputs, context, parents)
      end

      # HANDLE IN CLASSES
      # if action == 'update'
      #   input_field :id, types.ID
      # end
      # fields.each { |field_name, field_type| input_field field_name, mapping[field_type] }

      # klass = "#{type.camelize}Type".constantize
      # return_field type.to_sym, klass

      # return_field(:affectedId, types.ID) if type.to_s == 'project_media'

      # if type.to_s == 'team'
      #   return_field(:team_userEdge, TeamUserType.edge_type)
      #   return_field(:user, UserType)
      # end

      # if type =~ /^dynamic_annotation_/
      #   return_field :dynamic, DynamicType
      #   return_field :dynamicEdge, DynamicType.edge_type
      # end

      # return_field("versionEdge".to_sym, VersionType.edge_type) if ['task', 'comment'].include?(type.to_s) || type =~ /dynamic/
    end
  end
end
