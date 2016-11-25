module MediaAnnotationBase
  extend ActiveSupport::Concern

  included do
    include CheckdeskElasticSearchModel

    index_name CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']
    document_type 'projectmedia'

    attribute :annotation_type, String
    attribute :annotated_type, String
    attribute :annotated_id, String
    attribute :context_type, String
    attribute :context_id, String
    attribute :team_id, String
    attribute :annotator_type, String
    attribute :annotator_id, String
    attribute :entities, Array
    attribute :status, String
    attribute :title, String
    attribute :description, String
    attribute :quote, String

    before_validation :set_type

  end

  module ClassMethods

    def delete_all
      self.delete_index
      self.create_index
      sleep 1
    end

    def all_sorted(order = 'asc', field = 'created_at')
      type = self.name.parameterize
      query = type === 'annotation' ? { match_all: {} } : { bool: { must: [{ match: { annotation_type: type } }] } }
      self.search(query: query, sort: [{ field => { order: order }}, '_score'], size: 10000).results
    end

    def length
      type = self.name.parameterize
      self.count({ query: { bool: { must: [{ match: { annotation_type: type } }] } } })
    end
  end


  def save!
    raise 'Sorry, this is not valid' unless self.save
  end

  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class.name)
    self.send("#{name}_id=", obj.id)
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

end
