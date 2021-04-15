JSONAPI.configure do |config|
  # Built in paginators are :none, :offset, :paged
  config.default_paginator = :offset
  config.default_page_size = 10
  config.maximum_page_size = 50
  config.top_level_meta_include_record_count = true
  config.top_level_meta_record_count_key = :record_count
end
