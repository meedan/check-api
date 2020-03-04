namespace :check do
  namespace :migrate do
    task match_request_count_and_request_messages: :environment do
      smooch_bot = BotUser.where(login: 'smooch').last
      Dynamic.where(annotation_type: 'smooch', annotator_type: [nil], annotator_id: [nil])
      .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'")
      .where('pm.user_id' => smooch_bot.id, 'pm.id' => [128612, 128613])
      .find_in_batches(:batch_size => 25) do |dynamics|
      	df_ids = []
      	d_ids = []
      	User.current = smooch_bot
        dynamics.each do |d|
        	print "."
        	d_ids << d.id
          df = DynamicAnnotation::Field.where(annotation_id: d.id,  field_name: "smooch_data").last
          df_ids << df.id
          a = d.dup
          a.annotator = smooch_bot
          a.set_fields = { smooch_data: df.value }.to_json
          a.save!
        end
        User.current = nil
        DynamicAnnotation::Field.where(id: df_ids).delete_all
        Dynamic.where(id: d_ids).destroy_all
      end
    end
  end
end
