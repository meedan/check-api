class Profile < Source
	belongs_to :user

	notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }
	
end