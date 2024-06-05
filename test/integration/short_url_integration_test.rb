require_relative '../test_helper'

class ShortUrlIntegrationTest < ActionDispatch::IntegrationTest
  setup do
    redis = Redis.new(REDIS_CONFIG)
    redis.flushdb
  end

  test "should not access by other host other than the short host" do
    assert_routing "#{CheckConfig.get('short_url_host')}/x1y2z3", { host: 'localhost', controller: 'shortener/shortened_urls', action: 'show', id: 'x1y2z3' }
  end

  test "should redirect to 404 page if short URL doesn't exist" do
    get "#{CheckConfig.get('short_url_host')}/x1y2z3", params: {}
    assert_redirected_to '/404.html'
  end

  test "should redirect short URL to full URL" do
    pm = create_project_media
    short_url = pm.embed_url
    full_url = CheckConfig.get('pender_url') + '/api/medias.html?host=localhost&url=' + CGI.escape(pm.full_url)
    get short_url, params: {}
    assert_redirected_to full_url
  end
end
