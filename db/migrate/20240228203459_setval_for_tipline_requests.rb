class SetvalForTiplineRequests < ActiveRecord::Migration[6.1]
  def change
    # Set start value for the ID
    id = DynamicAnnotation::Field.where(field_name: 'smooch_data').last&.id || 0
    execute "SELECT setval('tipline_requests_id_seq', #{id})" if id > 0
  end
end
