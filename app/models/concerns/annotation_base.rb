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
          aggs = { g: { terms: { field: :annotator_id } } }
          annotators = []
          Annotation.search(query: query, aggs: aggs).response['aggregations']['g']['buckets'].each do |result|
            # result['doc_count'] is the number of annotations by this user
            annotators << User.find(result['key'])
          end
          annotators
        end
      end

      def has_annotations
        define_method :annotation_query do |type=nil, context=nil|
          matches = [{ match: { annotated_type: self.class.name } }, { match: { annotated_id: self.id.to_s } }]
          unless context.nil?
            matches << { match: { context_type: context.class.name } }
            matches << { match: { context_id: context.id.to_s } }
          end
          matches << { match: { annotation_type: type } } unless type.nil?
          { bool: { must: matches } }
        end

        define_method :annotation_relation do |type=nil, context=nil|
          query = self.annotation_query(type, context)
          params = { query: query, sort: [{ created_at: { order: 'desc' }}, '_score'] }
          ElasticsearchRelation.new(params)
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
    include CheckdeskElasticSearchModel
    include ActiveModel::Validations
    include PaperTrail::Model
    include CheckdeskPermissions
    include CheckdeskNotifications::Slack
    include CheckdeskNotifications::Pusher

    index_name CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']
    document_type 'annotation'

    attribute :annotation_type, String
    attribute :version_index, Integer
    attribute :annotated_type, String
    attribute :annotated_id, String
    attribute :context_type, String
    attribute :context_id, String
    attribute :annotator_type, String
    attribute :annotator_id, String

    before_validation :set_type_and_event, :set_annotator

    has_paper_trail on: [:update], save_changes: true

    after_save do
      Annotation.gateway.client.indices.refresh
      self.send(:record_update, true) unless self.attribute_changed?(:version_index)
      reset_changes
    end

    before_save :check_ability, :changes
    before_destroy :check_destroy_ability
  end

  module ClassMethods
    def has_many(name, scope = nil, options = {}, &extension)
      # Do nothing... instead, we are going to generate each collection we need
    end

    def after_commit(*args, &block)
      # Nothing - there is no commit in ElasticSearch
    end

    def after_rollback(*args, &block)
      # Nothing - there is no rollback in ElasticSearch
    end

    # We don't have associations, so we don't need it
    def reflect_on_all_associations(_macro = nil)
      []
    end

    def column_names
      self.attribute_set.to_a.map(&:name)
    end

    def columns_hash
      hash = {}
      self.attribute_set.to_a.each do |a|
        name = a.name.to_s
        type = a.type.to_s.gsub('Axiom::Types::', '').downcase.to_sym
        type = :datetime if type === :time
        hash[name] = OpenStruct.new({
          name: name,
          type: type
        })
      end
      hash
    end

    def columns
      objs = []
      self.attribute_set.to_a.each do |a|
        objs << OpenStruct.new({
          name: a.name.to_s,
          sql_type: a.type.to_s.gsub('Axiom::Types::', '')
        })
      end
      objs
    end

    def abstract_class?
      false
    end

    def delete_all
      self.delete_index
      self.create_index
      sleep 1
    end

    def all_sorted(order = 'asc', field = 'created_at')
      type = self.name.parameterize
      query = type === 'annotation' ? { match_all: {} } : { bool: { must: [{ match: { annotation_type: type } }] } }
      self.search(query: query, sort: [{ field => { order: order }}, '_score']).results
    end

    def length
      type = self.name.parameterize
      self.count({ query: { bool: { must: [{ match: { annotation_type: type } }] } } })
    end
  end

  def versions(options = {})
    PaperTrail::Version.where(options).where(item_type: self.class.to_s, item_id: self.id).order('id ASC')
  end

  def changed
    self.changes.keys
  end

  def changed_attributes
    ca = {}
    self.changed.each do |key|
      ca[key] = self.changes[key][0]
    end
    ca
  end

  def changes
    unless @changes
      changed = self.attributes
      unchanged = self.id.nil? ? {} : self.class.find(self.id).attributes
      @changes = {}
      changed.each do |k, v|
        next if [:created_at, :updated_at].include?(k)
        @changes[k] = [unchanged[k], v] unless unchanged[k] == v
      end
    end
    @changes
  end

  def attribute_changed?(attr)
    self.changed.map(&:to_sym).include?(attr.to_sym)
  end

  def attribute_names
    self.class.column_names
  end

  def has_attribute?(attr)
    self.attribute_names.include?(attr)
  end

  def revert(steps = 1, should_save = false)
    current_version = self.version_index.blank? ? (self.versions.size - 1) : self.version_index.to_i
    new_version = current_version - steps
    if new_version >= 0 && new_version < self.versions.size
      object = JSON.parse(self.versions[new_version].object).reject{ |k, _v| [:updated_at, :created_at].include?(k.to_sym) }.merge({ version_index: new_version })
      objchanges = JSON.parse(self.versions[new_version].object_changes)
      object.each do |k, v|
        self.send("#{k}=", v)
      end
      objchanges.each do |k, v|
        self.send("#{k}=", v[1])
      end
      self.save if should_save
    end
    self
  end

  def revert_and_save(steps = 1)
    self.reload
    self.revert(steps, true)
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
    {}.to_json
  end

  def current_user
    @current_user
  end

  def current_user=(user)
    @current_user = user
  end

  def context_team
    @context_team
  end

  def context_team=(team)
    @context_team = team
  end

  def origin
    @origin
  end

  def origin=(origin)
    @origin = origin
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

  def save!
    raise 'Sorry, this is not valid' unless self.save
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

  protected

  def load_polymorphic(name)
    type, id = self.send("#{name}_type"), self.send("#{name}_id")
    return nil if type.blank? && id.blank?
    type.constantize.find(id)
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

  def reset_changes
    @changes = nil
    self.reload
  end

  def set_annotator
    self.annotator = self.current_user if self.annotator.nil? && !self.current_user.nil?
  end
end
