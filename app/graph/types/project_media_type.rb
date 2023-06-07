# require "inclusions/task_and_annotation_fields"

class ProjectMediaType < DefaultObject
  # module TaskAndAnnotationFields
    # Inject field definitions into class
    # def self.included(base)
      # base.class_eval do
        # .field_annotations
        field :annotations,
              AnnotationUnion.connection_type,
              null: true do
          argument :annotation_type, String, required: true
        end

        # .field_annotations_count
        field :annotations_count, Integer, null: true do
          argument :annotation_type, String, required: true
        end

        # .field_tasks
        field :tasks, TaskType.connection_type, null: true do
          argument :fieldset, String, required: false
        end
      # end
    # end

    # For field: :tasks, imported by .field_tasks
    def tasks(**args)
      tasks =
        Task.where(
          annotation_type: "task",
          annotated_type: object.class.name,
          annotated_id: object.id
        )
      tasks = tasks.from_fieldset(args[:fieldset]) unless args["fieldset"].blank?
      # Order tasks by order field
      ids = tasks.to_a.sort_by { |task| task.order ||= 0 }.map(&:id)
      values = []
      ids.each_with_index { |id, i| values << "(#{id}, #{i})" }
      return tasks if values.empty?
      joins =
        ActiveRecord::Base.send(
          :sanitize_sql_array,
          [
            "JOIN (VALUES %s) AS x(value, order_number) ON %s.id = x.value",
            values.join(", "),
            "annotations"
          ]
        )
      tasks.joins(joins).order("x.order_number")
    end

    # For field: :annotations, imported by .field_annotations
    def annotations(**args)
      object.get_annotations(args[:annotation_type].split(",").map(&:strip))
    end

    # For field: :annotations_count, imported by .field_annotations_count
    def annotations_count(**args)
      object.get_annotations(args[:annotation_type].split(",").map(&:strip)).count
    end
  # end

  description "ProjectMedia type"

  implements NodeIdentification.interface

  field :media_id, Integer, null: true
  field :user_id, Integer, null: true
  field :url, String, null: true
  field :full_url, String, null: true
  field :quote, String, null: true
  field :oembed_metadata, String, null: true
  field :dbid, Integer, null: true
  field :archived, Integer, null: true
  field :author_role, String, null: true
  field :report_type, String, null: true
  field :title, String, null: true
  field :description, String, null: true
  field :picture, String, null: true
  field :virality, Integer, null: true
  field :requests_count, Integer, null: true
  field :demand, Integer, null: true
  field :linked_items_count, Integer, null: true
  field :last_seen, String, null: true
  field :status, String, null: true
  field :share_count, Integer, null: true
  field :list_columns_values, JsonString, null: true
  field :feed_columns_values, JsonString, null: true
  field :report_status, String, null: true
  field :confirmed_as_similar_by_name, String, null: true
  field :added_as_similar_by_name, String, null: true
  field :project_id, Integer, null: true
  field :source_id, Integer, null: true
  field :project_group, ProjectGroupType, null: true
  field :show_warning_cover, Boolean, null: true
  field :creator_name, String, null: true
  field :team_name, String, null: true
  field :channel, JsonString, null: true
  field :cluster_id, Integer, null: true
  field :cluster, ClusterType, null: true
  field :is_suggested, Boolean, null: true
  field :is_confirmed, Boolean, null: true

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

  field :is_read, Boolean, null: true do
    argument :by_me, Boolean, required: false
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

  field :type, String, null: true

  def type
    object.type_of_media
  end

  field :permissions, String, null: true

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

  field :domain, String, null: true

  def domain
    RecordLoader
      .for(Media)
      .load(object.media_id)
      .then { |media| media.respond_to?(:domain) ? media.domain : "" }
  end

  field :pusher_channel, String, null: true

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

  field :log,
        "VersionType",
        null: true,
        connection: true,
        resolve: ->(obj, args, _ctx) {
          obj.get_versions_log(
            args["event_types"],
            args["field_names"],
            args["annotation_types"],
            args["who_dunnit"],
            args["include_related"]
          )
        } do
    argument :event_types, String, required: false
    argument :field_names, String, required: false
    argument :annotation_types, String, required: false
    argument :who_dunnit, String, required: false
    argument :include_related, Boolean, required: false
  end

  field :log_count,
        Integer,
        null: true,
        resolve: ->(obj, _args, _ctx) { obj.get_versions_log_count }

  field :tags, "TagType", connection: true, null: true

  def tags
    object.get_annotations("tag").map(&:load)
  end

  field :comments, "CommentType", connection: true, null: true

  def comments
    object.get_annotations("comment").map(&:load)
  end

  field :requests,
        "DynamicAnnotationFieldType",
        connection: true,
        null: true

  def requests
    object.get_requests
  end

  field :last_status, String, null: true

  def last_status
    object.last_status
  end

  field :last_status_obj, "DynamicType", null: true

  def last_status_obj
    obj = object.last_status_obj
    obj.is_a?(Dynamic) ? obj : obj.load unless obj.nil?
  end

  field :published,
        String,
        null: true,
        resolve: ->(obj, _args, _ctx) { obj.created_at.to_i.to_s }

  field :language, String, null: true

  def language
    object.get_dynamic_annotation("language")&.get_field "language"&.send(:to_s)
  end

  field :language_code, String, null: true

  def language_code
    object.get_dynamic_annotation("language")&.get_field_value("language")
  end

  field :annotation, "AnnotationType", null: true do
    argument :annotation_type, String, required: true
  end

  def annotation(**args)
    object.get_dynamic_annotation(args[:annotation_type])
  end

  field :field_value, String, null: true do
    argument :annotation_type_field_name, String, required: true
  end

  def field_value(**args)
    annotation_type, field_name =
      args[:annotation_type_field_name].to_s.split(":")
    if !annotation_type.blank? && !field_name.blank?
      annotation = object.get_dynamic_annotation(annotation_type)
      annotation.nil? ? nil : annotation.get_field_value(field_name)
    end
  end

  field :assignments, "AnnotationType", connection: true, null: true do
    argument :user_id, Integer, required: true
    argument :annotation_type, String, required: true
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
      field "dynamic_annotations_#{type}".to_sym,
            "DynamicType",
            connection: true,
            null: true,
            resolve: ->(project_media, _args, _ctx) {
              project_media.get_annotations(type)
            }
      field "dynamic_annotation_#{type}".to_sym,
            "DynamicType",
            null: true,
            resolve: ->(project_media, _args, _ctx) {
              project_media.get_dynamic_annotation(type)
            }
    end

  field :suggested_similar_relationships,
        "RelationshipType",
        connection: true,
        null: true

  def suggested_similar_relationships
    ProjectMedia.get_similar_relationships(object, Relationship.suggested_type)
  end

  field :suggested_similar_items_count, Integer, null: true

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
        "RelationshipType",
        connection: true,
        null: true

  def confirmed_similar_relationships
    ProjectMedia.get_similar_relationships(object, Relationship.confirmed_type)
  end

  field :confirmed_similar_items_count, Integer, null: true

  def confirmed_similar_items_count
    ProjectMedia.get_similar_items(object, Relationship.confirmed_type).count
  end

  field :is_confirmed_similar_to_another_item, Boolean, null: true

  def is_confirmed_similar_to_another_item
    Relationship.confirmed_parent(object).id != object.id
  end

  field :confirmed_main_item, ProjectMediaType, null: true

  def confirmed_main_item
    Relationship.confirmed_parent(object)
  end

  field :default_relationships,
        "RelationshipType",
        connection: true,
        null: true

  def default_relationships
    object.get_default_relationships.order("id DESC")
  end

  field :default_relationships_count, Integer, null: true

  def default_relationships_count
    object.get_default_relationships.count
  end

  field :is_main, Boolean, null: true

  def is_main
    object.linked_items_count > 1 || object.suggestions_count > 0
  end

  field :is_secondary, Boolean, null: true

  def is_secondary
    object.sources_count > 0
  end

  field :similar_items,
        "ProjectMediaType",
        connection: true,
        null: true

  def similar_items
    object.similar_items
  end
end
