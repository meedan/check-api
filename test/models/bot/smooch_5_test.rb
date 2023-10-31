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

  # This test is taking 8 minutes to run. We should refactor it to reduce the runtime
  # Reference: CV2-2699
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
    ss = create_saved_search team_id: t1.id, filters: { show: ['claims', 'weblink'] }
    f1 = create_feed team_id: t1.id, published: true
    f1.teams << t2
    FeedTeam.update_all(shared: true)
    f1.teams << t3
    ft_ss = create_saved_search team_id: t1.id, filters: { keyword: 'Bar' }
    f1.saved_search = ft_ss
    f1.save!
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
end
