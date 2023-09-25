class AddKeywordsToTiplineResources < ActiveRecord::Migration[6.1]
  def change
    add_column :tipline_resources, :keywords, :string, array: true, default: []
  end
end
