class AddWhatsappConversationsToMonthlyTeamStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :monthly_team_statistics, :whatsapp_conversations, :integer
  end
end
