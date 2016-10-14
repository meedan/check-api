class RemoveDataFromMedias < ActiveRecord::Migration
  def change
    pender = Bot.where(name: 'Pender').last
    Media.find_each do |media|
      em = Embed.new
      em.embed = media.read_attribute(:data)
      em.annotated = media
      em.annotator = pender unless pender.nil?
      em.save!
     end

    remove_column :medias, :data
  end
end
