class AddCompletedKeyToCustomStatusesAgain < ActiveRecord::Migration
  def change
    Team.find_each do |t|
      if t.get_media_verification_statuses
        t.settings&.[](:media_verification_statuses)&.[](:statuses)&.each {|s| s[:completed] = '' unless s.key?(:completed)}
        t.save!
      end
    end
  end
end
