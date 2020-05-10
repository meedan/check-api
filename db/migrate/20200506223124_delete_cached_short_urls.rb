class DeleteCachedShortUrls < ActiveRecord::Migration
  def change
    Rails.cache.delete_matched("shorten-url-*")
  end
end
