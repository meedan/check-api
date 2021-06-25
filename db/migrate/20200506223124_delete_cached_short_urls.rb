class DeleteCachedShortUrls < ActiveRecord::Migration[4.2]
  def change
    Rails.cache.delete_matched("shorten-url-*")
  end
end
