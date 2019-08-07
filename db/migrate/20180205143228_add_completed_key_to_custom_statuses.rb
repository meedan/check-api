class AddCompletedKeyToCustomStatuses < ActiveRecord::Migration
  def change
    Team.find_each do |t|
      t.settings&.[](:media_verification_statuses)&.[](:statuses)&.each {|s| s[:completed] = ''}
      t.save!
    end
  end
end
