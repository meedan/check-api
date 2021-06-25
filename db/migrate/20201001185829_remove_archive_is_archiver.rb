class RemoveArchiveIsArchiver < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.write('check:migrate:remove_archive_is_archiver', nil)
  end
end
