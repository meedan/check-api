#!/usr/bin/env ruby
require './config/environment'
ApiKey.where(access_token: 'dev').destroy_all
api_key = ApiKey.create!
api_key.access_token = 'dev'
api_key.expire_at = api_key.expire_at.since(100.years)
api_key.save!
