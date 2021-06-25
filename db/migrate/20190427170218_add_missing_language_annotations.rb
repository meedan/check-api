class AddMissingLanguageAnnotations < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:add_missing_language_annotations:progress', nil)
  end
end
