require_relative '../../test_helper'
require 'sidekiq/testing'

class Bot::Smooch5Test < ActiveSupport::TestCase
  def setup
    super
    setup_smooch_bot
  end

  def teardown
    super
    CONFIG.unstub(:[])
    Bot::Smooch.unstub(:get_language)
  end

  test "should search for feed" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    # Create testing data
    t1 = create_team
    pm1a = create_project_media quote: 'Bar Test', team: t1 # Should be in search results
    pm1b = create_project_media quote: 'Test 1A', team: t1 # Should not be in search results because doesn't match this team's filters
    pm1c = create_project_media media: Blank.create!, team: t1 # Should not be in search results because doesn't match the feed filters
    pm1d = create_project_media quote: 'Foo Bar', team: t1 # Should not be in keyword search results because doesn't match the query filter but should be in similarity search results because it's returned from Alegre
    pm1e = create_project_media quote: 'Bar Test 2', team: t1 # Should not be in search results because it's not published
    pm1f = create_project_media quote: 'Bar Test 3', team: t1 # Should not be in similarity search results because it's not returned by Alegre but should be in keyword search results
    url = random_url
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item","title":"Bar","description":"Bar"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
    l = create_link url: url
    pm1g = create_project_media media: l, team: t1 # Should be only in search results by URL
    t2 = create_team
    pm2a = create_project_media quote: 'Test 2', team: t2 # Should be in search results
    pm2b = create_project_media media: l, team: t2 # Should be only in search results by URL
    t3 = create_team
    pm3a = create_project_media quote: 'Test 3', team: t3 # Should not be in search results (team is part of feed but sharing is disabled)
    pm3b = create_project_media media: l, team: t3 # Should not be in search results by URL
    t4 = create_team
    pm4a = create_project_media quote: 'Test 4', team: t4 # Should not be in search results (team is not part of feed)
    pm4b = create_project_media media: l, team: t4 # Should not be in search results by URL
    f1 = create_feed published: true, filters: { show: ['claims', 'links'] }
    f1.teams << t1
    f1.teams << t2
    FeedTeam.update_all(shared: true)
    f1.teams << t3
    ft = FeedTeam.where(feed: f1, team: t1).last
    ft.filters = { keyword: 'Bar' }
    ft.save!
    u = create_bot_user
    [t1, t2, t3, t4].each { |t| TeamUser.create!(user: u, team: t, role: 'editor') }
    alegre_results = {}
    ProjectMedia.order('id ASC').all.each_with_index do |pm, i|
      publish_report(pm) if pm.id != pm1e.id
      alegre_results[pm.id] = { score: (1 - i / 10.0), model: 'elasticsearch' } unless [pm1f, pm1g, pm2b].map(&:id).include?(pm.id)
    end
    Bot::Alegre.stubs(:get_merged_similar_items).returns(alegre_results)
    Bot::Alegre.stubs(:get_items_with_similar_media).returns(alegre_results)

    # Get feed data scoped by teams that are part of the feed, taking into account the filters for the feed
    # and for each team participating in the feed
    with_current_user_and_team(u, t1) do

      # Keyword search
      assert_equal [pm1a, pm1f, pm2a].sort, Bot::Smooch.search_for_similar_published_fact_checks('text', 'Test', [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a.sort

      # Text similarity search
      assert_equal [pm1a, pm1d, pm2a], Bot::Smooch.search_for_similar_published_fact_checks('text', 'This is a test', [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a

      # Media similarity search
      assert_equal [pm1a, pm1d, pm2a], Bot::Smooch.search_for_similar_published_fact_checks('image', random_url, [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a

      # URL search
      assert_equal [pm1g, pm2b].sort, Bot::Smooch.search_for_similar_published_fact_checks('text', "Test with URL: #{url}", [t1.id, t2.id, t3.id, t4.id], nil, f1.id).to_a.sort
    end

    Bot::Alegre.unstub(:get_merged_similar_items)
    Bot::Alegre.unstub(:get_items_with_similar_media)
  end

  test "should sort keyword search results by score" do
    RequestStore.store[:skip_cached_field_update] = false
    setup_elasticsearch

    t = create_team
    pm1 = create_project_media quote: 'Foo Bar', team: t
    pm2 = create_project_media quote: 'Foo Bar Test', team: t
    pm3 = create_project_media quote: 'Foo Bar Test Testing', team: t
    [pm1, pm2, pm3].each { |pm| publish_report(pm) }
    sleep 3 # Wait for ElasticSearch to index content

    assert_equal [pm1.id, pm2.id, pm3.id], Bot::Smooch.search_for_similar_published_fact_checks('text', 'Foo Bar', [t.id]).to_a.map(&:id)
  end

  test "should store media" do
    f = create_feed
    f.set_media_headers = { 'Authorization' => 'App 123456' }
    f.save!
    media_url = random_url
    WebMock.stub_request(:get, media_url).to_return(body: File.read(File.join(Rails.root, 'test', 'data', 'rails.png')))
    local_media_url = Bot::Smooch.save_locally_and_return_url(media_url, 'image', f.id)
    assert_match /^http/, local_media_url
    assert_not_equal media_url, local_media_url
  end
end
