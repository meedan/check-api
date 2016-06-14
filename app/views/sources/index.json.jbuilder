json.array!(@sources) do |source|
  json.extract! source, :id, :name, :slogan
  json.url source_url(source, format: :json)
end
