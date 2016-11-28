class MediaSearch

  include CheckElasticSearchModel

  attribute :team_id, String
  attribute :project_id, String
  attribute :annotated_type, String
  attribute :annotated_id, String
  attribute :status, String
  attribute :title, String
  attribute :description, String
  attribute :quote, String
  attribute :last_activity_at, Time, default: lambda { |o,a| Time.now.utc }

  before_save :set_last_activity_at

  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class.name)
    self.send("#{name}_id=", obj.id)
  end

  private

  def set_last_activity_at
    self.last_activity_at = Time.now.utc
  end

end
