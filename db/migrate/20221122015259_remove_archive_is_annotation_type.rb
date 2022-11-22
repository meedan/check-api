class RemoveArchiveIsAnnotationType < ActiveRecord::Migration[5.2]
  class DynamicAnnotationType < ActiveRecord::Base
    self.table_name = :dynamic_annotation_annotation_types
  end

  def change
    DynamicAnnotationType.where(annotation_type: 'archive_is').delete_all
  end
end
