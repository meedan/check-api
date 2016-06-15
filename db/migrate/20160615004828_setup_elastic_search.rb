class SetupElasticSearch < ActiveRecord::Migration
  MODELS = [Comment]

  def up
    MODELS.each do |model|
      model.delete_index
      model.create_index
    end
  end

  def down
    MODELS.each do |model|
      model.delete_index
    end
  end
end
