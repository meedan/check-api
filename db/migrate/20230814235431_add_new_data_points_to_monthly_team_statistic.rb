class AddNewDataPointsToMonthlyTeamStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :monthly_team_statistics, :published_reports, :integer
    add_column :monthly_team_statistics, :positive_searches, :integer
    add_column :monthly_team_statistics, :negative_searches, :integer
    add_column :monthly_team_statistics, :newsletters_sent, :integer
  end
end
