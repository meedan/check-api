class ConvertSubdomainToSlug < ActiveRecord::Migration[4.2]
  def change
    rename_column :teams, :subdomain, :slug
  end
end
