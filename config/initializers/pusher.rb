require 'pusher'

Pusher.app_id = CheckConfig.get('pusher_app_id')
Pusher.key = CheckConfig.get('pusher_key')
Pusher.secret = CheckConfig.get('pusher_secret')
Pusher.cluster = CheckConfig.get('pusher_cluster')
Pusher.logger = Rails.logger
Pusher.encrypted = true
Pusher.timeout = 30
