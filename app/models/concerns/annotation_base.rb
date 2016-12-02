module AnnotationBase
  extend ActiveSupport::Concern

  module Association
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
      def define_annotators_method
        define_method :annotators do |context=nil|
          query = self.annotation_query(context)
          query[:annotator_type] = 'User'
          annotators = []
          Annotation.group(:annotator_id, :id).having(query).each do |result|
            annotators << User.find(result.annotator_id)
          end
          annotators.uniq
        end
      end

      def has_annotations
        define_method :annotation_query do |type=nil, context=nil|
          matches = { annotated_type: self.class.name, annotated_id: self.id }
          if context.kind_of?(ActiveRecord::Base)
            matches[:context_type] = context.class.name
            matches[:context_id] = context.id
          end
          matches[:annotation_type] = [*type] unless type.nil?
          matches
        end

        define_method :annotation_relation do |type=nil, context=nil|
          query = self.annotation_query(type, context)
          klass = (type.blank? || type.is_a?(Array)) ? Annotation : type.camelize.constantize
          relation = klass.where(query)
          relation = relation.where(context_id: nil) if context == 'none'
          relation = relation.where.not(context_id: nil) if context == 'some'
          relation.order('id DESC')
        end

        define_method :annotations do |type=nil, context=nil|
          self.annotation_relation(type, context).all
        end

        define_method :annotations_count do |type=nil, context=nil|
          self.annotation_relation(type, context).count
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
    include CheckdeskPermissions
    include CheckdeskNotifications::Slack
    include CheckdeskNotifications::Pusher

    attr_accessor :disable_es_callbacks
    self.table_name = 'annotations'

    notifies_pusher on: :save,
                    if: proc { |a| a.annotated_type === 'Media' && a.context_type === 'Project' },
                    event: 'media_updated',
                    targets: proc { |a| [a.context, a.annotated] },
                    data: proc { |a| a.to_json }

    before_validation :set_type_and_event, :set_annotator
    after_initialize :start_serialized_fields

    has_paper_trail on: [:create, :update], save_changes: true, ignore: [:updated_at, :created_at, :id, :entities]

    serialize :data, HashWithIndifferentAccess
    serialize :entities, Array

    private

    def start_serialized_fields
      self.data ||= {}
      self.entities ||= []
    end
  end

  module ClassMethods
    def all_sorted(order = 'asc', field = 'created_at')
      type = self.name.parameterize
      query = type === 'annotation' ? {} : { annotation_type: type }
      Annotation.where(query).order(field => order.to_sym).all
    end

    def length
      type = self.name.parameterize
      Annotation.where(annotation_type: type).count
    end

    def field(name, _type = String, _options = {})
      attr_accessible name

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
    PaperTrail::Version.where(options).where(item_type: self.class.to_s, item_id: self.id).order('id ASC')
  end

  def source
    self.annotated
  end

  def media
    self.annotated
  end

  def project
    self.annotated
  end

  def annotated
    self.load_polymorphic('annotated')
  end

  def annotated=(obj)
    self.set_polymorphic('annotated', obj) unless obj.nil?
  end

  def context
    self.load_polymorphic('context')
  end

  def context=(obj)
    self.set_polymorphic('context', obj) unless obj.nil?
  end

  def annotator
    self.load_polymorphic('annotator')
  end

  def annotator=(obj)
    self.set_polymorphic('annotator', obj) unless obj.nil?
  end

  # Overwrite in the annotation type and expose the specific fields of that type
  def content
    self.data.to_json
  end

  def is_annotation?
    true
  end

  def ==(annotation)
    self.id == annotation.id
  end

  def dbid
    self.id
  end

  def get_team
    obj = self.context.nil? ? self.annotated : self.context
    team = []
    unless obj.nil?
      team = obj.respond_to?(:team) ? [obj.team.id] : obj.get_team
    end
    team
  end

  def current_team
    self.context.team if self.context_type === 'Project'
  end

  def should_notify?
    self.current_user.present? && self.current_team.present? && self.current_team.setting(:slack_notifications_enabled).to_i === 1 && self.annotated_type === 'Media'
  end

  # Supports only media for the time being
  def entity_objects
    objects = []
    self.entities.collect do |e|
      pm = ProjectMedia.where(id: e).last
      unless pm.nil?
        media = pm.media
        media.project_id = pm.project_id
        objects << media
      end
    end
    objects
  end

  def method_missing(method, *args, &block)
    (args.empty? && !block_given?) ? self.data[method] : super
  end

  def update_media_search(keys)
    return if self.disable_es_callbacks
    ms = get_elasticsearch_parent
    unless ms.nil?
      store_elasticsearch_data(ms, keys)
    end
  end

  def add_update_media_search_child(child, keys)
    return if self.disable_es_callbacks
    # get parent
    ms = get_elasticsearch_parent
    unless ms.nil?
      child = child.singularize.camelize.constantize
      model = child.search(query: { match: { _id: self.id } }).results.last
      if  model.nil?
        model = child.new
        model.id = self.id
      end
      store_elasticsearch_data(model, keys, {parent: ms.id})
      # resave parent to update last_activity_at
      ms.save!
    end
  end

  def store_elasticsearch_data(model, keys, options = {})
    keys.each do |k|
      model.send("#{k}=", self.data[k]) if model.respond_to?("#{k}=")
    end
    model.save!(options)
  end

  def get_elasticsearch_parent
    pm = self.annotated_id if self.annotated_type == 'ProjectMedia'
    pm = ProjectMedia.where(project_id: self.context_id, media_id: self.annotated_id).last if pm.nil?
    sleep 1 if Rails.env == 'test'
    MediaSearch.search(query: { match: { annotated_id: pm.id } }).last unless pm.nil?
  end

  protected

  def load_polymorphic(name)
    type, id = self.send("#{name}_type"), self.send("#{name}_id")
    return nil if type.blank? && id.blank?
    Rails.cache.fetch("find_#{type.parameterize}_#{id}", expires_in: 30.seconds) do
      type.constantize.find(id)
    end
  end

  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class.name)
    self.send("#{name}_id=", obj.id)
  end

  private

  def set_type_and_event
    self.annotation_type ||= self.class.name.parameterize
    self.paper_trail_event = 'create' if self.versions.count === 0
  end

  def set_annotator
    self.annotator = self.current_user if self.annotator.nil? && !self.current_user.nil?
  end
end
