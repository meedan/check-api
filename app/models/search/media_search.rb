class MediaSearch

  include CheckElasticSearchModel

  attribute :team_id, Integer
  attribute :project_id, Integer
  attribute :annotated_type, String, mapping: { type: 'text' }
  attribute :annotated_id, Integer
  attribute :associated_type, String, mapping: { type: 'keyword' }
  attribute :relationship_sources, Array, mapping: { type: 'text' }
  attribute :title, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :description, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :quote, String, mapping: { type: 'text', analyzer: 'check' }
  attribute :accounts, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      username: { type: 'text', analyzer: 'check'},
      title: { type: 'text', analyzer: 'check'},
      description: { type: 'text', analyzer: 'check'}
    }
  }
  attribute :comments, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'text'},
      text: { type: 'text', analyzer: 'check'}
    }
  }
  attribute :tags, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      tag: { type: 'text', analyzer: 'check', fields: { raw: { type: 'text' } } }
    }
  }

  attribute :dynamics, Array, mapping: {
    type: 'nested',
    properties: {
      id: { type: 'integer'},
      datetime: { type: 'integer' },
      location: { type: 'geo_point' },
      indexable: { type: 'text', analyzer: 'check'},
      language: { type: 'text', analyzer: 'keyword' },
      deadline: { type: 'integer' }
    }
  }

  def set_es_annotated(obj)
    self.send("annotated_type=", obj.class.name)
    self.send("annotated_id=", obj.id)
  end

  def set_es_nested_obj(obj)
    # comments
    updated_at = []
    comments = obj.annotations('comment')
    self.comments = comments.collect{|c| {id: c.id, text: c.text}}
    # get maximum updated_at for recent_acitivty sort
    max_updated_at = comments.max_by(&:updated_at)
    updated_at << max_updated_at.updated_at unless max_updated_at.nil?
    if obj.class.name == 'ProjectMedia'
      # tags
      tags = obj.get_annotations('tag').map(&:load)
      self.tags = tags.collect{|t| {id: t.id, tag: t.tag_text}}
      max_updated_at = tags.max_by(&:updated_at)
      updated_at << max_updated_at.updated_at unless max_updated_at.nil?
      # Dynamics
      dynamics = []
      obj.annotations.where("annotation_type LIKE 'task_response%'").find_each do |d|
        d = d.load
        options = d.get_elasticsearch_options_dynamic
        dynamics << d.store_elasticsearch_data(options[:keys], options[:data])
        updated_at << d.updated_at
      end
      self.dynamics = dynamics
    end
    self.updated_at = updated_at.max unless updated_at.blank?
  end
end
