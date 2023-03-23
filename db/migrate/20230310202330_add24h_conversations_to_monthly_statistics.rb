class Add24hConversationsToMonthlyStatistics < ActiveRecord::Migration[5.2]
  def change
    add_column :monthly_team_statistics, :conversations_24hr, :integer
  end
end
