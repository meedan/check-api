class SetvalForTiplineRequests < ActiveRecord::Migration[6.1]
  def change
    # Set start value for the ID
    annotation_id = DynamicAnnotation::Field.where(field_name: 'smooch_data').order('id ASC').last&.id || 0
    tipline_request_id = TiplineRequest.order('id ASC').last&.id || 0
    id = [annotation_id, tipline_request_id].max
    execute "SELECT setval('tipline_requests_id_seq', #{id})" if id > 0
  end
end
