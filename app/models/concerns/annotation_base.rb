module AnnotationBase
  extend ActiveSupport::Concern

  module Association
    def self.included(base)
      base.send :extend, ClassMethods
    end 
    
    module ClassMethods
      def has_annotations
        define_method :annotations do |context=nil|
          matches = [{ match: { annotated_type: self.class.name } }, { match: { annotated_id: self.id.to_s } }]
          unless context.nil?
            matches << { match: { context_type: context.class.name } } 
            matches << { match: { context_id: context.id.to_s } } 
          end
          query = { bool: { must: matches } }
          Annotation.search(query: query).results.map(&:load)
        end

        define_method :add_annotation do |annotation|
          annotation.annotated = self
          annotation.save
        end
      end
    end
  end

  included do
    include CheckdeskElasticSearchModel
    include ActiveModel::Validations
    include PaperTrail::Model
    
    index_name [Rails.application.engine_name, Rails.env, 'annotations'].join('_')
    document_type 'annotation'

    attribute :annotation_type, String
    attribute :version_index, Integer
    attribute :annotated_type, String
    attribute :annotated_id, String
    attribute :context_type, String
    attribute :context_id, String

    before_validation :set_type_and_event

    has_paper_trail on: [:update], save_changes: true

    after_save do
      self.send(:record_update, true) unless self.attribute_changed?(:version_index)
      reset_changes
    end

    before_save :changes
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
  end

  def versions(options = {})
    PaperTrail::Version.where(options).where(item_type: self.class.to_s, item_id: self.id)
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

  def annotated
    self.load_polymorphic('annotated')
  end

  def annotated=(obj)
    self.set_polymorphic('annotated', obj)
  end

  def context
    self.load_polymorphic('context')
  end

  def context=(obj)
    self.set_polymorphic('context', obj)
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
    self.annotation_type = self.class.name.parameterize
    self.paper_trail_event = 'create' if self.versions.count === 0
  end

  def reset_changes
    @changes = nil
    self.reload
  end
end
