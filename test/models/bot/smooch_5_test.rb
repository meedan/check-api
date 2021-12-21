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

  test "should update cached field when request is created or deleted" do
    RequestStore.store[:skip_cached_field_update] = false
    create_annotation_type_and_fields('Smooch', { 'Data' => ['JSON', true] })
    pm = create_project_media
    assert_equal 0, pm.reload.requests_count
    d = create_dynamic_annotation annotation_type: 'smooch', annotated: pm
    assert_equal 1, pm.reload.requests_count
    d.destroy
    assert_equal 0, pm.reload.requests_count
  end

  test "should go through menus" do
    setup_smooch_bot(true)
    @team.set_languages ['en', 'pt']
    @team.save!
    uid = random_string
    sm = CheckStateMachine.new(uid)
    rss = '<rss version="1"><channel><title>x</title><link>x</link><description>x</description><item><title>x</title><link>x</link></item></channel></rss>'
    WebMock.stub_request(:get, 'http://test.com/feed.rss').to_return(status: 200, body: rss)
    Sidekiq::Testing.fake! do
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot('Hello', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('9', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot('What?', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('What??', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('Hum', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(' ONE', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('ONE ', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('4', uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(' ONE', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('ONE ', uid)
      send_message_to_smooch_bot('2', uid)
      assert_equal 'query', sm.state.value
      send_message_to_smooch_bot('0', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      assert_equal 'en', Bot::Smooch.get_user_language({ 'authorId' => uid })
      send_message_to_smooch_bot('3', uid)
      assert_equal 'main', sm.state.value
      assert_equal 'pt', Bot::Smooch.get_user_language({ 'authorId' => uid })
      send_message_to_smooch_bot('um', uid)
      assert_equal 'query', sm.state.value
    end
    Rails.cache.stubs(:read).returns(nil)
    Rails.cache.stubs(:read).with("smooch:last_message_from_user:#{uid}").returns(Time.now + 10.seconds)
    assert_difference 'ProjectMedia.count' do
      send_message_to_smooch_bot(random_string, uid)
    end
    Rails.cache.unstub(:read)
    assert_equal 'waiting_for_message', sm.state.value
    @team.set_languages ['en']
    @team.save!
  end

  test "should transition from query state to query state" do
    uid = random_string
    sm = CheckStateMachine.new(uid)
    assert_nothing_raised do
      sm.go_to_query
      sm.go_to_query
    end
  end

  test "should timeout menu status" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      assert_equal 'waiting_for_message', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      Sidekiq::Worker.drain_all
      assert_equal 'waiting_for_message', sm.state.value
    end
    Time.unstub(:now)
  end

  test "should create smooch annotation for user requests" do
    MESSAGE_BOUNDARY = "\u2063"
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      now = Time.now
      uid = random_string
      sm = CheckStateMachine.new(uid)
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('1', uid)
      conditions = {
        annotation_type: 'smooch',
        annotated_type: @pm_for_menu_option.class.name,
        annotated_id: @pm_for_menu_option.id
      }
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      a = Dynamic.where(conditions).last
      f = a.get_field_value('smooch_data')
      text  = JSON.parse(f)['text'].split("\n#{MESSAGE_BOUNDARY}")
      # verify that all messages stored
      assert_equal 3, text.size
      assert_equal '1', text.last
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot('1', uid)
      assert_difference "Dynamic.where(#{conditions}).count", 1 do
        Sidekiq::Worker.drain_all
      end
      a = Dynamic.where(conditions).last
      f = a.get_field_value('smooch_data')
      text  = JSON.parse(f)['text'].split("\n#{MESSAGE_BOUNDARY}")
      # verify that all messages stored
      assert_equal 5, text.size
      assert_equal '1', text.last
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 1 do
        Sidekiq::Worker.drain_all
      end
      send_message_to_smooch_bot(random_string, uid)
      send_message_to_smooch_bot(random_string, uid)
      Time.stubs(:now).returns(now + 30.minutes)
      assert_difference 'Annotation.where(annotation_type: "smooch").count', 1 do
        Sidekiq::Worker.drain_all
      end
    end
    Time.unstub(:now)
  end

  test "should not raise exception if can't parse RSS feed" do
    BotUser.delete_all
    assert_nothing_raised do
      Bot::Smooch.refresh_rss_feeds_cache
    end
  end

  test "should take a shortcut to subscribe or unsubscribe to newsletter" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      uid = random_string
      sm = CheckStateMachine.new(uid)
      assert_difference 'TiplineSubscription.count' do
        send_message_to_smooch_bot('subscribe', uid)
      end
      assert_difference 'TiplineSubscription.count', -1 do
        send_message_to_smooch_bot('unsubscribe', uid)
      end
    end
  end

  test "should subscribe or unsubscribe to newsletter" do
    setup_smooch_bot(true)
    Sidekiq::Testing.fake! do
      uid = random_string
      sm = CheckStateMachine.new(uid)
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      send_message_to_smooch_bot('0', uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      assert_difference 'TiplineSubscription.count' do
        send_message_to_smooch_bot('1', uid)
      end
      send_message_to_smooch_bot(random_string, uid)
      assert_equal 'main', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'secondary', sm.state.value
      send_message_to_smooch_bot('5', uid)
      assert_equal 'subscription', sm.state.value
      assert_difference 'TiplineSubscription.count', -1 do
        send_message_to_smooch_bot('1', uid)
      end
    end
  end

  test "should return search results for bot v2" do
    assert_kind_of Array, Bot::Smooch.get_search_results(random_string, nil, nil)
  end

  test "should use bot v2 when search result is empty" do
    setup_smooch_bot(true, { 'smooch_version' => 'v2', 'smooch_disable_timeout' => true })
    uid = random_string
    sm = CheckStateMachine.new(uid)

    Sidekiq::Testing.inline! do
      Bot::Smooch.stubs(:get_search_results).returns([])
      sm.reset
      Bot::Smooch.clear_user_bundled_messages(uid)
      send_message_to_smooch_bot('Foo', uid)
      assert_equal 'first', sm.state.value
      send_message_to_smooch_bot('2', uid)
      assert_equal 'add_more_details', sm.state.value
      send_message_to_smooch_bot('Bar', uid)
      assert_equal 'add_more_details', sm.state.value
      assert_difference 'ProjectMedia.count' do
        send_message_to_smooch_bot('1', uid)
      end
    end
    Bot::Smooch.unstub(:get_search_results)
  end

  test "should use bot v2 when search result is not empty but not relevant" do
    setup_smooch_bot(true, { 'smooch_version' => 'v2', 'smooch_disable_timeout' => true })
    uid = random_string
    sm = CheckStateMachine.new(uid)

    Sidekiq::Testing.inline! do
      Bot::Smooch.stubs(:get_search_results).returns([create_project_media(team: @team)])
      sm.reset
      Bot::Smooch.clear_user_bundled_messages(uid)
      send_message_to_smooch_bot('Foo', uid)
      assert_equal 'first', sm.state.value
      send_message_to_smooch_bot('2', uid)
      assert_equal 'add_more_details', sm.state.value
      send_message_to_smooch_bot('Bar', uid)
      assert_equal 'add_more_details', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'search_result', sm.state.value
      assert_difference 'ProjectMedia.count' do
        send_message_to_smooch_bot('2', uid)
      end
    end
    Bot::Smooch.unstub(:get_search_results)
  end

  test "should use bot v2 when search result is not empty and relevant" do
    setup_smooch_bot(true, { 'smooch_version' => 'v2', 'smooch_disable_timeout' => true })
    uid = random_string
    sm = CheckStateMachine.new(uid)

    Sidekiq::Testing.inline! do
      Bot::Smooch.stubs(:get_search_results).returns([create_project_media(team: @team)])
      sm.reset
      Bot::Smooch.clear_user_bundled_messages(uid)
      send_message_to_smooch_bot('Foo', uid)
      assert_equal 'first', sm.state.value
      send_message_to_smooch_bot('2', uid)
      assert_equal 'add_more_details', sm.state.value
      send_message_to_smooch_bot('Bar', uid)
      assert_equal 'add_more_details', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'search_result', sm.state.value
      assert_no_difference 'ProjectMedia.count' do
        send_message_to_smooch_bot('1', uid)
      end
    end
    Bot::Smooch.unstub(:get_search_results)
  end

  test "should go to search state" do
    setup_smooch_bot(true, { 'smooch_version' => 'v2' })
    uid = random_string
    sm = CheckStateMachine.new(uid)

    Sidekiq::Testing.fake! do
      send_message_to_smooch_bot('Foo', uid)
      assert_equal 'first', sm.state.value
      send_message_to_smooch_bot('1', uid)
      assert_equal 'search', sm.state.value
      send_message_to_smooch_bot('Bar', uid)
    end
  end

  test "should handle search error" do
    assert_nothing_raised do
      Bot::Smooch.stubs(:get_search_results).raises(StandardError)
      Bot::Smooch.search(random_string, random_string, nil, nil, nil)
      Bot::Smooch.unstub(:get_search_results)
    end
  end

  test "should perform a keyword search if text with less or equal to 3 words" do
    t = create_team
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => 'Foo bar' })
    CheckSearch.any_instance.stubs(:medias).returns([pm])

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    CheckSearch.any_instance.unstub(:medias)
  end

  test "should perform a text similarity search if text with more than 3 words" do
    t = create_team
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'text', 'text' => 'Foo bar foo bar foo bar' })
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    Bot::Alegre.stubs(:get_similar_texts).returns({ pm.id => 0.9 })

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    Bot::Alegre.unstub(:get_similar_texts)
  end

  test "should perform a media similarity search" do
    t = create_team
    b = create_bot_user login: 'alegre', name: 'Alegre', approved: true
    b.install_to!(t)
    tbi = TeamBotInstallation.where(team_id: t.id, user_id: b.id).last
    tbi.set_similarity_date_threshold = 6
    tbi.set_date_similarity_threshold_enabled = true
    tbi.save!
    pm = create_project_media team: t

    Bot::Smooch.stubs(:bundle_list_of_messages).returns({ 'type' => 'image', 'mediaUrl' => 'https://image' })
    ProjectMedia.any_instance.stubs(:report_status).returns('published')
    Bot::Alegre.stubs(:get_items_with_similar_media).returns({ pm.id => 0.9 })

    assert_equal [pm], Bot::Smooch.get_search_results(random_string, {}, pm.team_id)

    Bot::Smooch.unstub(:bundle_list_of_messages)
    ProjectMedia.any_instance.unstub(:report_status)
    Bot::Alegre.unstub(:get_items_with_similar_media)
  end

  test "should handle exception when adding Smooch integration" do
    SmoochApi::IntegrationApi.any_instance.stubs(:create_integration).raises(SmoochApi::ApiError)
    assert_nothing_raised do
      @installation.smooch_add_integration('telegram', { token: random_string })
    end
    SmoochApi::IntegrationApi.any_instance.unstub(:create_integration)
  end

  test "should format newsletter time as cron" do
    # Regular time
    settings = {
      'smooch_newsletter_time' => '10',
      'smooch_newsletter_timezone' => 'BRT',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '0 13 * * 0', Bot::Smooch.newsletter_cron(settings)

    # Non-integer hours offset, but still same day as UTC
    settings = {
      'smooch_newsletter_time' => '19',
      'smooch_newsletter_timezone' => 'IST',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '30 13 * * 0', Bot::Smooch.newsletter_cron(settings)

    # Non-integer hours offset and not same day as UTC
    settings = {
      'smooch_newsletter_time' => '1',
      'smooch_newsletter_timezone' => 'IST',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '30 19 * * 6', Bot::Smooch.newsletter_cron(settings)

    # Integer hours offset and not same day as UTC
    settings = {
      'smooch_newsletter_time' => '23',
      'smooch_newsletter_timezone' => 'PDT',
      'smooch_newsletter_day' => 'sunday'
    }
    assert_equal '0 6 * * 1', Bot::Smooch.newsletter_cron(settings)
  end
end
