class AddChannelToExplainersAndFactChecks < ActiveRecord::Migration[6.1]
  def change
    # Defaulting to 1 ("manual")
    add_column :explainers, :channel, :integer, null: false, default: 1
    add_index  :explainers, :channel

    add_column :fact_checks, :channel, :integer, null: false, default: 1
    add_index  :fact_checks, :channel
  end
end