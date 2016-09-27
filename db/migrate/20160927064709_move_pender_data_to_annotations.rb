class MovePenderDataToAnnotations < ActiveRecord::Migration
  def change
    pender = Bot.where(name: 'Pender').last
    Media.find_each do |media|
      em = Embed.new
      em.embed = media.data
      em.annotated = media
      em.annotator = pender unless pender.nil?
      em.save!
     end
  end
end
