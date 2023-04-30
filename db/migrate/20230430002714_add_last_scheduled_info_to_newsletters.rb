class AddLastScheduledInfoToNewsletters < ActiveRecord::Migration[6.0]
  def change
    add_column :tipline_newsletters, :last_scheduled_by_id, :integer
    add_column :tipline_newsletters, :last_scheduled_at, :datetime
  end
end
