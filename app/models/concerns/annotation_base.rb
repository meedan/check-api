module AnnotationBase
  extend ActiveSupport::Concern

  module Association
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def define_annotators_method
        define_method :annotators do
          query = self.annotation_query
          query[:annotator_type] = 'User'
          annotators = []
          Annotation.group(:annotator_id, :id).having(query).each{ |result| annotators << User.find(result.annotator_id) }
          annotators.uniq
        end
      end

      def define_annotation_relation_method
        define_method :annotation_relation do |type=nil|
          query = self.annotation_query(type)
          klass = (type.blank? || type.is_a?(Array)) ? Annotation : type.camelize.constantize
          klass.where(query).order('id DESC')
        end
      end

      def has_annotations
        define_method :annotation_query do |type=nil|
          matches = { annotated_type: self.class_name, annotated_id: self.id }
          matches[:annotation_type] = [*type] unless type.nil?
          matches
        end

        define_annotation_relation_method

        define_method :annotations do |type=nil|
          self.annotation_relation(type).all
        end

        define_method :annotations_count do |type=nil|
          self.annotation_relation(type).count
        end

        define_method :add_annotation do |annotation|
          annotation.annotated = self
          annotation.save
        end

        define_annotators_method
      end
    end
  end

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include PaperTrail::Model
    include CheckPermissions
    include CheckNotifications::Pusher
    include CheckElasticSearch
    include CustomLock
    include AssignmentConcern
    include AnnotationPrivate

    attr_accessor :disable_es_callbacks, :is_being_copied, :force_version
    self.table_name = 'annotations'

    notifies_pusher on: :save,
                    if: proc { |a| ['ProjectMedia', 'ProjectSource', 'Source'].include?(a.annotated_type) && !['slack_message', 'smooch_response'].include?(a.annotation_type) && !a.skip_notifications },
                    event: proc { |a| a.annotated_type == 'ProjectMedia' ? 'media_updated' : 'source_updated'},
                    targets: proc { |a| a.annotated_type == 'ProjectMedia' ? [a.annotated.project, a.annotated.media] : (a.annotated_type == 'ProjectSource' ? [a.annotated.source] : [a.annotated]) },
                    data: proc { |a| a = Annotation.where(id: a.id).last; a.nil? ? a.to_json : a.load.to_json }

    before_validation :set_type_and_event, :set_annotator
    after_initialize :start_serialized_fields
    after_create :notify_team_bots_create
    after_commit :assign_to_users, on: :create
    after_update :notify_team_bots_update, :notify_bot_author
    after_save :touch_annotated, unless: proc { |a| a.is_being_copied }
    after_destroy :touch_annotated

    has_paper_trail on: [:create, :update, :destroy], save_changes: true, ignore: [:updated_at, :created_at, :id, :entities, :lock_version], if: proc { |a| (User.current.present? && !a.is_being_copied) || a.force_version }

    has_many :assignments, ->{ where(assigned_type: 'Annotation') }, foreign_key: :assigned_id, dependent: :destroy

    serialize :data, HashWithIndifferentAccess
    serialize :entities, Array

    custom_optimistic_locking if: proc { |a| a.annotation_type == 'metadata' }

    validate :annotated_is_not_archived, unless: proc { |a| a.is_being_copied }

    def annotations
      Annotation.where(annotated_type: ['Task', 'Annotation', 'Dynamic', 'Flag', 'Tag', 'Comment', 'Embed'], annotated_id: self.id)
    end

    def start_serialized_fields
      self.data ||= {}
      self.entities ||= []
    end

    def touch_annotated
      annotated = self.annotated
      unless annotated.nil?
        annotated.skip_check_ability = annotated.skip_notifications = true # the notification will be triggered by the annotation already
        annotated.skip_clear_cache = self.skip_clear_cache
        annotated.updated_at = Time.now
        annotated.disable_es_callbacks = (Rails.env.to_s == 'test')
        ActiveRecord::Base.connection_pool.with_connection do
          annotated.save!(validate: false)
        end
      end
    end

    def annotated_is_not_archived
      annotated = self.annotated ? self.annotated.reload : nil
      if annotated && annotated.respond_to?(:archived) && annotated.archived
        errors.add(:base, I18n.t(:error_annotated_archived))
      end
    end

    def propagate_assignment_to(user)
      if self.annotation_type == 'verification_status' || self.annotation_type == 'translation_status'
        self.annotated.get_annotations('task').map(&:load).select{ |task| task.status == 'unresolved' || task.responses.select{ |r| r.annotator_id.to_i == user.id }.last.nil? }
      else
        []
      end
    end

    def assign_to_users
      users = []
      if self.annotation_type == 'task'
        status_id = self.annotated&.last_status_obj&.id
        users = User.joins(:assignments).where('assignments.assigned_id' => status_id, 'assignments.assigned_type' => 'Annotation').map(&:id).uniq
      elsif self.annotation_type == 'verification_status' || self.annotation_type == 'translation_status'
        project_id = self.annotated&.project_id
        users = User.joins(:assignments).where('assignments.assigned_id' => project_id, 'assignments.assigned_type' => 'Project').map(&:id).uniq
      end
      Assignment.delay.bulk_assign(YAML::dump(self), users) unless users.empty?
    end
  end

  module ClassMethods
    def all_sorted(order = 'asc', field = 'created_at')
      type = self.name.parameterize
      query = type === 'annotation' ? {} : { annotation_type: type }
      Annotation.where(query).order(field => order.to_sym).all
    end

    def length
      Annotation.where(annotation_type: self.name.parameterize).count
    end

    def field(name, _type = String, _options = {})
      define_method "#{name}=" do |value=nil|
        self.data ||= {}
        self.data[name.to_sym] = value
      end

      define_method name do
        self.data ||= {}
        self.data[name.to_sym]
      end
    end
  end

  def versions(options = {})
    PaperTrail::Version.where(options).where(item_type: [self.class.to_s], item_id: self.id).order('id ASC')
  end

  def source
    self.annotated
  end

  def project_media
    self.annotated_type == 'ProjectMedia' ? self.annotated : (self.annotated.project_media if self.annotated.respond_to?(:project_media))
  end

  def project_source
    self.annotated if self.annotated_type == 'ProjectSource'
  end

  def project
    self.annotated if self.annotated_type == 'Project'
  end

  def task
    self.annotated if self.annotated_type == 'Task'
  end

  def annotated
    self.load_polymorphic('annotated')
  end

  def annotated=(obj)
    self.set_polymorphic('annotated', obj) unless obj.nil?
  end

  def annotator
    self.load_polymorphic('annotator')
  end

  def annotator=(obj)
    self.set_polymorphic('annotator', obj) unless obj.nil?
  end

  # Overwrite in the annotation type and expose the specific fields of that type
  def content
    fields = self.get_fields
    fields.empty? ? self.data.merge(self.image_data).to_json : fields.to_json
  end

  def get_fields
    DynamicAnnotation::Field.where(annotation_id: self.id).to_a
  end

  def is_annotation?
    true
  end

  def ==(annotation)
    annotation.respond_to?(:id) ? (self.id == annotation.id) : super
  end

  def dbid
    self.id
  end

  def relay_id(type)
    str = "#{type.capitalize}/#{self.id}"
    str += "/#{self.version.id}" unless self.version.nil?
    Base64.encode64(str)
  end

  def get_team
    team = []
    obj = self.annotated
    obj = obj.annotated if obj.respond_to?(:annotated)
    obj = obj.project if obj.respond_to?(:project)
    if !obj.nil? && obj.respond_to?(:team)
      team = [obj.team.id] unless obj.team.nil?
    end
    team
  end

  def current_team
    self.annotated.project.team if self.annotated_type === 'ProjectMedia' && self.annotated.project
  end

  # Supports only media for the time being
  def entity_objects
    ProjectMedia.where(id: self.entities).to_a
  end

  def method_missing(key, *args, &block)
    (args.empty? && !block_given?) ? self.data[key] : super
  end

  def annotation_type_class
    klass = nil
    begin
      klass = self.annotation_type.camelize.constantize
    rescue NameError
      klass = Dynamic
    end
    klass
  end

  def image_data
    self.file.nil? ? {} : { embed: self.load.embed_path, thumbnail: self.load.thumbnail_path, original: self.load.image_path }
  end

  def annotator_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def annotated_id_callback(value, mapping_ids = nil, type = ProjectMedia)
    annotated = type.where(id: mapping_ids[value]).last
    annotated.nil? ? nil : annotated.id
  end

  def to_s
    self.annotated.title
  end

  def annotated_is_archived?
    self.annotated.present? && self.annotated.respond_to?(:archived) && self.annotated_type.constantize.where(id: self.annotated_id, archived: true).last.present?
  end

  def slack_params
    object = self.project_media || self.project_source
    item = self.annotated_type == 'ProjectSource' ? object.source.name : object.title
    item_type = self.annotated_type == 'ProjectSource' ? 'source' : object.media.class.name.underscore
    annotation_type = self.class.name == 'Dynamic' ? item_type : self.class.name.underscore
    user = User.current or self.annotator
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      project: Bot::Slack.to_slack(object.project.title),
      role: I18n.t("role_" + user.role(object.project.team).to_s),
      team: Bot::Slack.to_slack(object.project.team.name),
      item: Bot::Slack.to_slack_url(object.full_url, item),
      type: I18n.t("activerecord.models.#{annotation_type}"),
      parent_type: I18n.t("activerecord.models.#{item_type}"),
      url: object.full_url,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{annotation_type}"), app: CONFIG['app_name']
      })
    }.merge(self.slack_params_assignment)
  end

  protected

  def load_polymorphic(name)
    type, id = self.send("#{name}_type"), self.send("#{name}_id")
    return nil if type.blank? || id.blank?
    Rails.cache.fetch("find_#{type.parameterize}_#{id}", expires_in: 30.seconds, race_condition_ttl: 30.seconds) do
      type.constantize.where(id: id).last
    end
  end

  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class_name)
    self.send("#{name}_id=", obj.id)
  end

  # private
  #
  # Please add private methods to app/models/concerns/annotation_private.rb
end
