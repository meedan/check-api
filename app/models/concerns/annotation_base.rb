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
          klass = (type.blank? || type.is_a?(Array)) ? Annotation : (begin type.camelize.constantize rescue Annotation end)
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
    include CheckPusher
    include CheckElasticSearch
    include CustomLock
    include AssignmentConcern
    include AnnotationPrivate

    attr_accessor :disable_es_callbacks, :is_being_copied, :force_version, :skip_trashed_validation
    self.table_name = 'annotations'

    notifies_pusher on: :save,
                    if: proc { |a| ['ProjectMedia', 'Source'].include?(a.annotated_type) && !['slack_message', 'smooch_response'].include?(a.annotation_type) && !a.skip_notifications },
                    event: proc { |a| a.annotated_type == 'ProjectMedia' ? 'media_updated' : 'source_updated'},
                    targets: proc { |a| a.annotated_type == 'ProjectMedia' ? [a.annotated&.media] : [a.annotated] },
                    data: proc { |a| a = Annotation.where(id: a.id).last; a.nil? ? a.to_json : a.load.to_json }

    before_validation :remove_null_bytes, :set_type_and_event, :set_annotator
    after_initialize :start_serialized_fields
    after_create :notify_team_bots_create
    after_update :notify_team_bots_update, :notify_bot_author
    after_save :touch_annotated, unless: proc { |a| a.is_being_copied }
    after_commit :notify_team_bots_save, on: [:create, :update]

    has_paper_trail on: [:create, :update, :destroy], save_changes: true, ignore: [:updated_at, :created_at, :id, :entities, :lock_version], if: proc { |a| (User.current.present? && ['tag', 'report_design', 'verification_status'].include?(a.annotation_type) && !a.is_being_copied) || a.force_version }, versions: { class_name: 'Version' }

    has_many :assignments, ->{ where(assigned_type: 'Annotation') }, foreign_key: :assigned_id, dependent: :destroy

    serialize :data, HashWithIndifferentAccess
    serialize :entities, Array

    custom_optimistic_locking if: proc { |a| a.annotation_type == 'metadata' && a.annotated_type == 'Source' }

    validate :annotated_is_not_archived, unless: proc { |a| a.is_being_copied }, if: proc { |_a| !User.current.nil? && User.current.type != 'BotUser' }

    def annotations
      Annotation.where(annotated_type: ['Task', 'Annotation', 'Dynamic', 'Tag'], annotated_id: self.id)
    end

    def start_serialized_fields
      self.data ||= {}
      self.entities ||= []
    end

    def touch_annotated
      annotated = self.annotated
      unless annotated.nil?
        if annotated.is_a?(Link)
          # the notification will be triggered by the annotation already
          annotated.skip_check_ability = annotated.skip_notifications = true
          annotated.skip_clear_cache = self.skip_clear_cache
          annotated.updated_at = Time.now
          annotated.disable_es_callbacks = true
          ApplicationRecord.connection_pool.with_connection do
            annotated.save!(validate: false)
          end
        elsif annotated.is_a?(ProjectMedia) && User.current.present?
          if ['report_design', 'tag', 'archiver'].include?(self.annotation_type)
            self.update_recent_activity(annotated)
          end
        end
      end
    end

    def annotated_is_not_archived
      annotated = self.annotated ? self.annotated.reload : nil
      if annotated && annotated.respond_to?(:archived) && annotated.archived == CheckArchivedFlags::FlagCodes::TRASHED && self.annotator_type != 'BotUser' && !self.skip_trashed_validation
        errors.add(:base, I18n.t(:error_annotated_archived))
      end
    end

    def propagate_assignment_to(user)
      if self.annotation_type == 'verification_status'
        self.annotated.get_annotations('task').map(&:load).reject{ |task| task.nil? }.select{ |task| task.responses.count == 0 || task.responses.select{ |r| r.annotator_id.to_i == user&.id }.last.nil? }
      else
        []
      end
    end

    def parsed_fragment
      list = begin
        JSON.parse(Addressable::URI.unescape(self.fragment))
      rescue
        [self.fragment]
      end

      list.map! do |fragment|
        begin
          URI.media_fragment(fragment)
        rescue
          {}
        end
      end
      list.size == 1 ? list.first : list
    end

    def custom_permissions(ability = nil)
      perms = {}
      perms["destroy Smooch"] = ability.can?(:destroy, self) if self.annotation_type == 'smooch'
      perms
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

  def annotation_versions(options = {})
    Version.from_partition(self.team&.id).where(options).where(item_type: [self.class.to_s], item_id: self.id).order('id ASC')
  end

  def source
    self.annotated
  end

  def project_media
    self.annotated_type == 'ProjectMedia' ? self.annotated : (self.annotated.project_media if self.annotated.respond_to?(:project_media))
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
    fields.empty? ? self.data.merge(self.file_data).to_json : fields.to_json
  end

  def get_fields
    if self.json_schema.blank?
      DynamicAnnotation::Field.where(annotation_id: self.id).to_a
    else
      data = self.read_attribute(:data) || {}
      fields = []
      data.each do |key, value|
        fields << OpenStruct.new({ field_name: key, value: value })
      end
      fields
    end
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

  def team
    return @team if @team
    obj = self.annotated if self.annotated
    obj = obj.annotated if obj.respond_to?(:annotated)
    obj.nil? ? nil: obj.team
  end

  def current_team
    team = nil
    team = self.annotated.team if self.annotated_type === 'ProjectMedia'
    team
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

  def file_data
    a = Annotation.where(id: self.id).last
    return {} if a.nil?
    a.file.nil? ? {} : (a.load&.file&.is_a?(Array) ? { file_urls: a.load.file.collect{ |f| f.file.public_url } } : { embed: a.load&.embed_path, thumbnail: a.load&.thumbnail_path, original: a.load&.image_path })
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

  def annotated_is_trashed?
    self.annotated.present? && self.annotated.respond_to?(:archived) && self.annotated_type.constantize.where(id: self.annotated_id, archived: CheckArchivedFlags::FlagCodes::TRASHED).last.present?
  end

  def slack_params
    object = self.project_media
    item = object.title
    item_type = object.media.class.name.underscore
    annotation_type = self.class.name == 'Dynamic' ? item_type : self.class.name.underscore
    user = User.current || self.annotator
    team = object.team
    {
      user: Bot::Slack.to_slack(user.name),
      user_image: user.profile_image,
      role: I18n.t("role_" + user.role(team).to_s),
      team: Bot::Slack.to_slack(team.name),
      item: Bot::Slack.to_slack_url(object.full_url, item),
      type: I18n.t("activerecord.models.#{annotation_type}"),
      parent_type: I18n.t("activerecord.models.#{item_type}"),
      url: object.full_url,
      button: I18n.t("slack.fields.view_button", **{
        type: I18n.t("activerecord.models.#{annotation_type}"), app: CheckConfig.get('app_name')
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
