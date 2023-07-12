class AddNewslettersDeliveredToMonthlyTeamStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :monthly_team_statistics, :newsletters_delivered, :integer
  end
end
