class AddTypeToMedia < ActiveRecord::Migration
  def change
    add_column :medias, :type, :string
    Media.all.each do |media|
      type = media.url.blank? ? 'Claim' : 'Link'
      media.update_column(:type, type)
    end
  end
end
