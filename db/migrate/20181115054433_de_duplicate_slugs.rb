class DeDuplicateSlugs < ActiveRecord::Migration[4.2]
  def change
    duplicates = Team.group(:slug).count.select{ |k, v| v > 1 }
    duplicates.each do |slug, count|
      Team.where(slug: slug).all.each_with_index do |t, index|
        next if index == 0
        t.update_column :slug, "#{t.slug}-#{index}"
      end
    end
  end
end
