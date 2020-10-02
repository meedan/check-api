class RemoveArchiveIsArchiver < ActiveRecord::Migration
  def change
    Rails.cache.write('check:migrate:remove_archive_is_archiver', nil)
  end
end
