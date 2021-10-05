class AddIndexToMedias < ActiveRecord::Migration[4.2]
  def change
    #add_column :medias, :url, :string
    # remove duplicate URLs
    m = Media.all.group_by { |x| x.url }
    m.each do |key, value|
      value.each_with_index do |row, index|
        unless value.length == 1
          if index == value.length - 1
            row.destroy
          end
        end
      end
    end
    add_index :medias, :url, unique: true
  end
end
