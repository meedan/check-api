class ReattributeAnnotationsToBots < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:reattribute_annotations_to_bots:progress', nil)
  end
end
