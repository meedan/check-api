class ProjectMediaType < DefaultObject
  include Types::Inclusions::TaskAndAnnotationFields

  description "ProjectMedia type"

  implements GraphQL::Types::Relay::Node

  field :media_id, GraphQL::Types::Int, null: true
  field :user_id, GraphQL::Types::Int, null: true
  field :url, GraphQL::Types::String, null: true
  field :full_url, GraphQL::Types::String, null: true
  field :quote, GraphQL::Types::String, null: true
  field :oembed_metadata, GraphQL::Types::String, null: true
  field :dbid, GraphQL::Types::Int, null: true
  field :archived, GraphQL::Types::Int, null: true
  field :author_role, GraphQL::Types::String, null: true
  field :report_type, GraphQL::Types::String, null: true
  field :title, GraphQL::Types::String, null: true
  field :description, GraphQL::Types::String, null: true
  field :picture, GraphQL::Types::String, null: true
  field :virality, GraphQL::Types::Int, null: true
  field :requests_count, GraphQL::Types::Int, null: true
  field :demand, GraphQL::Types::Int, null: true
  field :linked_items_count, GraphQL::Types::Int, null: true
  field :last_seen, GraphQL::Types::String, null: true
  field :status, GraphQL::Types::String, null: true
  field :share_count, GraphQL::Types::Int, null: true
  field :list_columns_values, JsonString, null: true
  field :feed_columns_values, JsonString, null: true
  field :report_status, GraphQL::Types::String, null: true
  field :confirmed_as_similar_by_name, GraphQL::Types::String, null: true
  field :added_as_similar_by_name, GraphQL::Types::String, null: true
  field :project_id, GraphQL::Types::Int, null: true
  field :source_id, GraphQL::Types::Int, null: true
  field :project_group, ProjectGroupType, null: true
  field :show_warning_cover, GraphQL::Types::Boolean, null: true
  field :creator_name, GraphQL::Types::String, null: true
  field :team_name, GraphQL::Types::String, null: true
  field :channel, JsonString, null: true
  field :cluster_id, GraphQL::Types::Int, null: true
  field :cluster, ClusterType, null: true
  field :is_suggested, GraphQL::Types::Boolean, null: true
  field :is_confirmed, GraphQL::Types::Boolean, null: true

  field :claim_description, ClaimDescriptionType, null: true

  def claim_description
    pm =
      Relationship
        .where("relationship_type = ?", Relationship.confirmed_type.to_yaml)
        .where(target_id: object.id)
        .first
        &.source || object
    pm.claim_description
  end

  field :is_read, GraphQL::Types::Boolean, null: true do
    argument :by_me, GraphQL::Types::Boolean, required: false, camelize: false
  end

  def is_read(**args)
    if args[:by_me]
      !ProjectMediaUser
        .where(
          project_media_id: object.id,
          user_id: User.current&.id,
          read: true
        )
        .last
        .nil?
    else
      object.read
    end
  end

  field :type, GraphQL::Types::String, null: true

  def type
    object.type_of_media
  end

  field :permissions, GraphQL::Types::String, null: true

  def permissions
    PermissionsLoader
      .for(context[:ability])
      .load(object.id)
      .then { |pm| pm.cached_permissions || pm.permissions }
  end

  field :tasks_count, JsonString, null: true

  def tasks_count
    {
      all: object.all_tasks.size,
      open: object.open_tasks.size,
      completed: object.completed_tasks.size
    }
  end

  field :domain, GraphQL::Types::String, null: true

  def domain
    RecordLoader
      .for(Media)
      .load(object.media_id)
      .then { |media| media.respond_to?(:domain) ? media.domain : "" }
  end

  field :pusher_channel, GraphQL::Types::String, null: true

  def pusher_channel
    RecordLoader
      .for(Media)
      .load(object.media_id)
      .then { |media| media.pusher_channel }
  end

  field :account, AccountType, null: true

  def account
    RecordLoader
      .for(Media)
      .load(object.media_id)
      .then { |obj| RecordLoader.for(Account).load(obj.account_id) }
  end

  field :team, TeamType, null: true

  def team
    RecordLoader.for(Team).load(object.team_id)
  end

  field :project, ProjectType, null: true

  def project
    RecordLoader.for(Project).load(object.project_id)
  end

  field :media, MediaType, null: true

  def media
    RecordLoader.for(Media).load(object.media_id)
  end

  field :user, UserType, null: true

  def user
    RecordLoader
      .for(User)
      .load(object.user_id)
      .then do |user|
        ability = context[:ability] || Ability.new
        user if ability.can?(:read, user)
      end
  end

  field :source, SourceType, null: true

  def source
    RecordLoader.for(Source).load(object.source_id)
  end

  field :log, VersionType.connection_type, null: true do
    argument :event_types, [GraphQL::Types::String], required: false, camelize: false
    argument :field_names, [GraphQL::Types::String], required: false, camelize: false
    argument :annotation_types, [GraphQL::Types::String], required: false, camelize: false
    argument :who_dunnit, [GraphQL::Types::String], required: false, camelize: false
    argument :include_related, GraphQL::Types::Boolean, required: false, camelize: false
  end

  def log(event_types: nil, field_names: nil, annotation_types: nil, who_dunnit: nil, include_related: nil)
    object.get_versions_log(event_types, field_names, annotation_types, who_dunnit, include_related)
  end

  field :log_count, GraphQL::Types::Int, null: true

  def log_count
    object.get_versions_log_count
  end

  field :tags, TagType.connection_type, null: true

  def tags
    object.get_annotations("tag").map(&:load)
  end

  field :comments, CommentType.connection_type, null: true

  def comments
    object.get_annotations("comment").map(&:load)
  end

  field :requests,
        DynamicAnnotationFieldType.connection_type,
        null: true

  def requests
    object.get_requests
  end

  field :last_status, GraphQL::Types::String, null: true

  field :last_status_obj, DynamicType, null: true

  def last_status_obj
    obj = object.last_status_obj
    obj.is_a?(Dynamic) ? obj : obj.load unless obj.nil?
  end

  field :published, GraphQL::Types::String, null: true

  def published
    object.created_at.to_i.to_s
  end

  field :language, GraphQL::Types::String, null: true

  def language
    object.get_dynamic_annotation("language")&.get_field "language"&.send(:to_s)
  end

  field :language_code, GraphQL::Types::String, null: true

  def language_code
    object.get_dynamic_annotation("language")&.get_field_value("language")
  end

  field :annotation, AnnotationType, null: true do
    argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
  end

  def annotation(**args)
    object.get_dynamic_annotation(args[:annotation_type])
  end

  field :field_value, GraphQL::Types::String, null: true do
    argument :annotation_type_field_name, GraphQL::Types::String, required: true, camelize: false
  end

  def field_value(**args)
    annotation_type, field_name =
      args[:annotation_type_field_name].to_s.split(":")
    if !annotation_type.blank? && !field_name.blank?
      annotation = object.get_dynamic_annotation(annotation_type)
      annotation.nil? ? nil : annotation.get_field_value(field_name)
    end
  end

  field :assignments, AnnotationType.connection_type, null: true do
    argument :user_id, GraphQL::Types::Int, required: true, camelize: false
    argument :annotation_type, GraphQL::Types::String, required: true, camelize: false
  end

  def assignments(**args)
    Annotation.joins(:assignments).where(
      "annotations.annotated_type" => "ProjectMedia",
      "annotations.annotated_id" => object.id,
      "assignments.user_id" => args[:user_id],
      "annotations.annotation_type" => args[:annotation_type]
    )
  end

  DynamicAnnotation::AnnotationType
    .select("annotation_type")
    .map(&:annotation_type)
    .each do |type|
      field "dynamic_annotations_#{type}".to_sym, DynamicType.connection_type, null: true

      define_method("dynamic_annotations_#{type}".to_sym) do |**_inputs|
        object.get_annotations(type)
      end

      field "dynamic_annotation_#{type}".to_sym, DynamicType, null: true

      define_method("dynamic_annotation_#{type}".to_sym) do |**_inputs|
        object.get_dynamic_annotation(type)
      end
    end

  field :suggested_similar_relationships,
        RelationshipType.connection_type,
        null: true

  def suggested_similar_relationships
    ProjectMedia.get_similar_relationships(object, Relationship.suggested_type)
  end

  field :suggested_similar_items_count, GraphQL::Types::Int, null: true

  def suggested_similar_items_count
    ProjectMedia.get_similar_items(object, Relationship.suggested_type).count
  end

  field :suggested_main_item, ProjectMediaType, null: true

  def suggested_main_item
    Relationship
      .where("relationship_type = ?", Relationship.suggested_type.to_yaml)
      .where(target_id: object.id)
      .first
      &.source
  end

  field :confirmed_similar_relationships,
        RelationshipType.connection_type,
        null: true

  def confirmed_similar_relationships
    ProjectMedia.get_similar_relationships(object, Relationship.confirmed_type)
  end

  field :confirmed_similar_items_count, GraphQL::Types::Int, null: true

  def confirmed_similar_items_count
    ProjectMedia.get_similar_items(object, Relationship.confirmed_type).count
  end

  field :is_confirmed_similar_to_another_item, GraphQL::Types::Boolean, null: true

  def is_confirmed_similar_to_another_item
    Relationship.confirmed_parent(object).id != object.id
  end

  field :confirmed_main_item, ProjectMediaType, null: true

  def confirmed_main_item
    Relationship.confirmed_parent(object)
  end

  field :default_relationships,
        RelationshipType.connection_type,
        null: true

  def default_relationships
    object.get_default_relationships.order("id DESC")
  end

  field :default_relationships_count, GraphQL::Types::Int, null: true

  def default_relationships_count
    object.get_default_relationships.count
  end

  field :is_main, GraphQL::Types::Boolean, null: true

  def is_main
    object.linked_items_count > 1 || object.suggestions_count > 0
  end

  field :is_secondary, GraphQL::Types::Boolean, null: true

  def is_secondary
    object.sources_count > 0
  end

  field :similar_items,
        ProjectMediaType.connection_type,
        null: true
end
