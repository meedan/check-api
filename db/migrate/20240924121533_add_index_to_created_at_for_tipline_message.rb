class AddIndexToCreatedAtForTiplineMessage < ActiveRecord::Migration[6.1]
  def change
    execute "CREATE INDEX tipline_message_created_at_year ON tipline_messages (date_trunc('year', created_at))" 
    execute "CREATE INDEX tipline_message_created_at_quarter ON tipline_messages (date_trunc('quarter', created_at))"
    execute "CREATE INDEX tipline_message_created_at_month ON tipline_messages (date_trunc('month', created_at))"
    execute "CREATE INDEX tipline_message_created_at_week ON tipline_messages (date_trunc('week', created_at))"
    execute "CREATE INDEX tipline_message_created_at_day ON tipline_messages (date_trunc('day', created_at))"
    add_index :tipline_messages, :created_at
  end
end
