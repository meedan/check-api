class ConvertSubdomainToSlug < ActiveRecord::Migration
  def change
    rename_column :teams, :subdomain, :slug
  end
end
