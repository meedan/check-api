class AddTitleToClusters < ActiveRecord::Migration[6.1]
  def change
    add_column :clusters, :title, :string
  end
end
