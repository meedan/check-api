class ConvertStatuses < ActiveRecord::Migration
  def change
    Status.all_sorted.each do |s|
      s.status = s.status.gsub(' ', '_').downcase
      s.save!
    end
  end
end
