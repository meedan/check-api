class MediaSearch < ActiveRecord::Base

  include CheckElasticSearchModel

  attribute :team_id, String
  attribute :project_id, String
  attribute :annotation_type, String
  attribute :annotated_type, String
  attribute :annotated_id, String
  attribute :status, String
  attribute :title, String
  attribute :description, String
  attribute :quote, String

  before_validation :set_type

  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class.name)
    self.send("#{name}_id=", obj.id)
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

end
