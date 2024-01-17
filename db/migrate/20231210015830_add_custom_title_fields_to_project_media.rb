class AddCustomTitleFieldsToProjectMedia < ActiveRecord::Migration[6.1]
  def change
    add_column :project_medias, :custom_title, :string, null: true
    add_column :project_medias, :title_field, :string, null: true
  end
end
