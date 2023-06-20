class BaseMutation < GraphQL::Schema::RelayClassicMutation
  class << self
    private

    def define_create_or_update_behavior(action, subclass, mutation_target, parents)
      subclass.graphql_name "#{action.camelize}#{mutation_target.camelize}"

      type_class = "#{mutation_target.camelize}Type".constantize
      subclass.field mutation_target, type_class, null: true, camelize: false
      subclass.field "#{type_class}Edge", type_class.edge_type, null: true

      set_parent_returns(subclass, parents)

      # HANDLE IN CLASSES / think this is done
      # return_field(:affectedId, types.ID) if type.to_s == 'project_media'

      # TODO: extract as TeamAttributes module / think this is done
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
    def set_parent_returns(klass, parents)
      parents.each do |parent_field|
        # If a return type has been manually specified, use that.
        # Otherwise, use the default (e.g. ProjectType for Project)
        #
        # This allows for specifying parents as:
        # PARENTS = ['team', my_team: TeamType], which would be same as:
        # PARENTS = [team: TeamType, my_team: TeamType]
        if parent_field.is_a?(Hash)
          parent_values = parent_field
          parent_field = parent_values.keys.first
          parent_type = parent_values[parent_field]
        else
          parent_type = "#{parent_field.to_s.camelize}Type".constantize
        end
        klass.field parent_field.to_sym, parent_type, null: true, camelize: false
      end
    end
  end
end
