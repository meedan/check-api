class AddPositiveFeedbackAndNegativeFeedbackToMonthlyTeamStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :monthly_team_statistics, :positive_feedback, :integer
    add_column :monthly_team_statistics, :negative_feedback, :integer
  end
end
