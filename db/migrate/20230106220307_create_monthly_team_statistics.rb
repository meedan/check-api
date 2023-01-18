class CreateMonthlyTeamStatistics < ActiveRecord::Migration[5.2]
  def change
    create_table :monthly_team_statistics do |t|
      t.integer :conversations
      t.integer :average_messages_per_day
      t.integer :unique_users
      t.integer :returning_users
      t.integer :valid_new_requests
      t.integer :published_native_reports
      t.integer :published_imported_reports
      t.integer :requests_answered_with_report
      t.integer :reports_sent_to_users
      t.integer :unique_users_who_received_report
      t.integer :median_response_time
      t.integer :unique_newsletters_sent
      t.integer :new_newsletter_subscriptions
      t.integer :newsletter_cancellations
      t.integer :current_subscribers

      t.datetime :start_date
      t.datetime :end_date
      t.string :platform
      t.string :language
      t.references :team, null: false, index: true
      t.timestamps null: false
      t.index [:team_id, :platform, :language, :start_date], unique: true, name: 'index_monthly_stats_team_platform_language_start'
    end
  end
end
