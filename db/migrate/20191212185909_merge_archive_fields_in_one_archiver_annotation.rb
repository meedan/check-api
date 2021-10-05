class MergeArchiveFieldsInOneArchiverAnnotation < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:merge_archive_fields_in_one_archiver_annotation:progress', nil)
  end
end
