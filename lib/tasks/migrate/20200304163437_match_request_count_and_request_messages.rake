namespace :check do
  namespace :migrate do
    task match_request_count_and_request_messages: :environment do
      smooch_bot = BotUser.where(login: 'smooch').last
      Dynamic.where(annotation_type: 'smooch', annotator_type: [nil], annotator_id: [nil])
      .joins("INNER JOIN project_medias pm ON pm.id = annotations.annotated_id AND annotations.annotated_type = 'ProjectMedia'")
      .where('pm.user_id' => smooch_bot.id)
      .find_in_batches(:batch_size => 2500) do |dynamics|
        dynamics.each do |d|
        	print "."
          df = DynamicAnnotation::Field.where(annotation_id: d.id,  field_name: "smooch_data").last
          unless df.nil?
            v = Version.new({
              item_type: 'DynamicAnnotation::Field',
              item_id: df.id.to_s,
              event: 'create',
              whodunnit: smooch_bot.id.to_s,
              object: nil,
              object_changes: {
                field_name: [nil, "smooch_data"],
                value: [nil, df.value.to_json],
                annotation_id: [nil, d.id],
                field_type: [nil, "json"],
                value_json: ["{}", df.value],
                id: [nil, df.id]
              }.to_json,
              created_at: d.created_at,
              meta: nil,
              event_type: 'create_dynamicannotationfield',
              object_after: d.to_json,
              associated_id: d.annotated_id,
              associated_type: d.annotated_type,
              team_id: d.annotated.team_id
            })
            v.save!
            d.update_columns(annotator_type: smooch_bot.class.name, annotator_id: smooch_bot.id)
          end
        end
      end
    end
  end
end
