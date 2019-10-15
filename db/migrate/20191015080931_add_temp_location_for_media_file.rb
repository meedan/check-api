class AddTempLocationForMediaFile < ActiveRecord::Migration
  def change
  	add_column :medias, :file_tmp, :string
  end
end
