class RemoveDataFromMedias < ActiveRecord::Migration[4.2]
  def change
    Media.find_each do |media|
      media.pender_data= media.read_attribute(:data)
      media.set_pender_result_as_annotation
     end

    remove_column :medias, :data
  end
end
