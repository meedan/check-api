require 'pusher'

Pusher.app_id = CONFIG['pusher_app_id']
Pusher.key = CONFIG['pusher_key']
Pusher.secret = CONFIG['pusher_secret']
Pusher.logger = Rails.logger
Pusher.encrypted = true
