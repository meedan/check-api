class UpdateFieldsFromInstagramSources < ActiveRecord::Migration
  def change
    n = 0
    Embed.where(annotation_type: 'embed', annotated_type: 'Account').find_each do |e|
      embed = JSON.parse(e.embed)
      e.skip_notifications = true
      if embed['provider'] == 'instagram'
        account = e.annotated
        account.validate_pender_result(true)
        if account.pender_data['error'].nil?
          account.set_pender_result_as_annotation
          account.sources.each do |source|
            source.name = account.data['author_name']
            source.avatar = account.data['author_picture']
            source.save!
            n += 1
          end
        end
      end
    end
    puts "Migration is finished! #{n} items were changed"
  end
end
