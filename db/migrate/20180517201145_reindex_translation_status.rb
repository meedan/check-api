class ReindexTranslationStatus < ActiveRecord::Migration
  def change
    DynamicAnnotation::Field.where(field_name: 'translation_status_status').find_each do |s|
      puts "Reindexing field #{s.id}"
      s.index_on_es
    end
  end
end
