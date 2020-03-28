development: &default
  secret_token: somethingsecret
  authorization_header: 'X-Check-Token'
  twitter_consumer_key: test
  twitter_consumer_secret: test
  facebook_app_id: 123456
  facebook_app_secret: test
  slack_app_id: 123456
  slack_app_secret: test
  pender_url: http://localhost:3005
  pender_url_private: http://localhost:3005
  pender_key: test
  elasticsearch_host: 127.0.0.1
  elasticsearch_port: 9200
  elasticsearch_log: false
  elasticsearch_sync: false
  checkdesk_client: 'http://localhost:3333'
  default_mail: root@localhost
  checkdesk_base_url: http://localhost:3000
  checkdesk_base_url_private: http://api:3000
  send_welcome_email_on_registration: false
  elasticsearch_index:
  # smtp mail settings
  smtp_host: smtp.gmail.com # (google's default)
  smtp_port: 587 # (google's default)
  smtp_user: user@host.com # usually your gmail account
  smtp_pass: 123456 # usually your gmail account password
  pusher_app_id:
  pusher_key:
  pusher_secret:
  pusher_cluster:
  video_file_max_size:
  uploaded_file_max_size:
  image_min_width:
  image_max_width:
  image_min_height:
  image_max_height:
  image_embed_size:
  image_thumbnail_size:
  clamav_service_path:
  transifex_user:
  transifex_password:
  transifex_project:
  locale:
  alegre_host:
  alegre_token:
  app_name: "Check"
  app_url: "http://checkmedia.org"
  support_email: "check@meedan.com"
  cc_deville_host:
  cc_deville_token:
  cc_deville_httpauth:
  google_analytics_code: # Format: 'UA-000000000-1'
  export_download_expiration_days: 7
  pg_hero_enabled: false
  tos_url: 'https://meedan.com/en/check/check_tos.html'
  tos_smooch_url:
    lang:
      en: 'https://meedan.com/en/check/check_message_tos.html'
      es: 'https://meedan.com/es/check/check_message_tos.html'
  privacy_policy_url: 'https://meedan.com/en/check/check_privacy.html'
  privacy_email: ''
  google_credentials_path: '/path/to/credentials.json'
  bitly_key: 'bitly-key'
  failed_attempts: 4
  two_factor_key: 'a3ebaae85c248da81427623959753e46b9fcb8a0d630a1e41c1dffe03596bf2ffd9701bf69fa0dd598f3c45103bdba7e956d0d3560916859884de92d1f51fe16'
  google_client_id:
  google_client_secret:
  google_auth_redirect_uri:
  # for production, don't use a wildcard: set the allowed domains explicitly, as a regular expression, for example: '(https?://.*\.?(meedan.com|meedan.org))'
  allowed_origins: '.*'
  smooch_twitter_consumer_key:
  smooch_twitter_consumer_secret:
  smooch_twitter_tier:
  smooch_twitter_env_name:
  storage:
    # If you are using Amazon S3, the user should have permissions like the one below and the bucket must be publicly readable
    # {
    #   "Version": "2012-10-17",
    #   "Statement": [
    #     {
    #       "Sid": "VisualEditor0",
    #       "Effect": "Allow",
    #       "Action": "s3:*",
    #       "Resource": [
    #         "arn:aws:s3:::bucket-name/*",
    #         "arn:aws:s3:::bucket-name"
    #       ]
    #     }
    #   ]
    # }
    endpoint:
    asset_host:
    access_key:
    secret_key:
    bucket:
    bucket_region:
    path_style:

test:
  <<: *default
  pender_key: test
  alegre_token: test
  elasticsearch_log: false

production:
  <<: *default