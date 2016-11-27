class MediaSearch < ActiveRecord::Base

  include CheckElasticSearchModel

  attribute :team_id, String
  attribute :project_id, String
  attribute :annotated_type, String
  attribute :annotated_id, String
  attribute :status, String
  attribute :title, String
  attribute :description, String
  attribute :quote, String



  def set_polymorphic(name, obj)
    self.send("#{name}_type=", obj.class.name)
    self.send("#{name}_id=", obj.id)
  end

end
