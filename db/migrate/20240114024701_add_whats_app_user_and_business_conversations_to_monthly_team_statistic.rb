class AddWhatsAppUserAndBusinessConversationsToMonthlyTeamStatistic < ActiveRecord::Migration[6.1]
  def change
    add_column :monthly_team_statistics, :whatsapp_conversations_user, :integer
    add_column :monthly_team_statistics, :whatsapp_conversations_business, :integer
  end
end
