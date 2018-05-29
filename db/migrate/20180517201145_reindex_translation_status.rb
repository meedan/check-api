class ReindexTranslationStatus < ActiveRecord::Migration
  def change
    DynamicAnnotation::Field.where(field_name: 'translation_status_status').find_each do |s|
      s.index_on_es
    end
  end
end
