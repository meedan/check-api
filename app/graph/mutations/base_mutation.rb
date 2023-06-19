class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class << self
    private

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

      # HANDLE IN CLASSES
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
