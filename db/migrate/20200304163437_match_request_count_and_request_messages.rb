class MatchRequestCountAndRequestMessages < ActiveRecord::Migration
  def change
  	Rails.cache.write('check:migrate:match_request_count_and_request_messages', Time.now)
  end
end
