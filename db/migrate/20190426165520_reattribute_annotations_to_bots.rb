class ReattributeAnnotationsToBots < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:reattribute_annotations_to_bots:progress', nil)
  end
end
