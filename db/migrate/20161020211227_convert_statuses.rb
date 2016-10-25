class ConvertStatuses < ActiveRecord::Migration
  def change
    Status.all_sorted.each do |s|
      puts "Converting status #{s.id}..."
      s.status = s.status.gsub(' ', '_').downcase
      s.save!
      sleep 1
    end
  end
end
