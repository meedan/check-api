class MediaSearch

  include CheckElasticSearchModel

  attribute :team_id, String
  attribute :project_id, String
  attribute :annotated_type, String
  attribute :annotated_id, String
  attribute :associated_type, String
  attribute :status, String
  attribute :title, String, mapping: { analyzer: 'check' }
  attribute :description, String, mapping: { analyzer: 'check' }
  attribute :quote, String, mapping: { analyzer: 'check' }
  attribute :last_activity_at, Time, default: lambda { |_o, _a| Time.now.utc }
  attribute :account, Array, mapping: {
    type: 'object',
    properties: {
      id: { type: 'string'},
      username: { type: 'string', analyzer: 'check'},
      title: { type: 'string', analyzer: 'check'},
      description: { type: 'string', analyzer: 'check'}
    }
  }

  def set_es_annotated(obj)
    self.send("annotated_type=", obj.class.name)
    self.send("annotated_id=", obj.id)
  end
end
