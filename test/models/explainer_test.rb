require_relative '../test_helper'

class ExplainerTest < ActiveSupport::TestCase
  def setup
    Explainer.delete_all
  end

  def teardown
    User.current = Team.current = nil
  end

  test "should create explainer" do
    assert_difference 'Explainer.count' do
      create_explainer
    end
  end

  test "should not create explainer without user or team" do
    assert_no_difference 'Explainer.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_explainer user: nil
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_explainer team: nil
      end
    end
    # should set default team
    t = create_team
    Team.stubs(:current).returns(t)
    ex = create_explainer team: nil
    assert_equal t, ex.team
    Team.unstub(:current)
  end

  test "should validate language" do
    t = create_team
    t.set_language = 'fr'
    t.set_languages(['fr'])
    t.save!
    assert_difference 'Explainer.count' do
      create_explainer team: t, language: nil
    end
    assert_difference 'Explainer.count' do
      create_explainer team: t, language: 'fr'
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_explainer team: t, language: 'en'
    end
  end

  test "should belong to user and team" do
    u = create_user
    t = create_team
    ex = create_explainer user: u, team: t
    assert_equal u, ex.user
    assert_equal t, ex.team
  end

  test "should not create an explainer if does not have permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    with_current_user_and_team(u, t) do
      assert_no_difference 'Explainer.count' do
        assert_raises RuntimeError do
          create_explainer team: create_team
        end
      end
    end
  end

  test "should create an explainer if has permission" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u
    with_current_user_and_team(u, t) do
      assert_difference 'Explainer.count' do
        create_explainer team: t
      end
    end
  end

  test "should tag explainer using annotation" do
    ex = create_explainer
    tag = create_tag annotated: ex
    assert_equal [tag], ex.annotations('tag')
  end

  test "should create tag texts when setting tags" do
    WebMock.stub_request(:post, /\/similarity\/async\/text/).to_return(body: {}.to_json) # For explainers
    Sidekiq::Testing.inline! do
      assert_difference 'TagText.count' do
        create_explainer tags: ['foo']
      end
    end
  end

  test "should index explainer information" do
    Sidekiq::Testing.inline!
    description = %{
      The is the first paragraph.

      This is the second paragraph.
    }

    # Index two paragraphs and title when the explainer is created
    Bot::Alegre.stubs(:request).with('post', '/similarity/async/text', anything).times(3)
    Bot::Alegre.stubs(:request).with('delete', '/text/similarity/', anything).never
    ex = create_explainer description: description

    # Update the index when paragraphs change
    Bot::Alegre.stubs(:request).with('post', '/similarity/async/text', anything).times(2)
    Bot::Alegre.stubs(:request).with('delete', '/text/similarity/', anything).once
    ex = Explainer.find(ex.id)
    ex.description = 'Now this is the only paragraph'
    ex.save!
  end

  test "should destroy explainer items when project media is destroyed" do
    t = create_team
    ex = create_explainer team: t
    pm = create_project_media team: t
    pm.explainers << ex
    assert_difference 'ExplainerItem.count', -1 do
      pm.destroy!
    end
  end

  test "should detach from items when explainer is sent to the trash" do
    Sidekiq::Testing.fake!
    t = create_team
    ex = create_explainer team: t
    pm = create_project_media team: t
    pm.explainers << ex
    assert_equal [ex], pm.reload.explainers
    assert_equal [pm], ex.reload.project_medias
    assert_difference 'ExplainerItem.count', -1 do
      ex = Explainer.find(ex.id)
      ex.trashed = true
      ex.save!
    end
    assert_equal [], pm.reload.explainers
    assert_equal [], ex.reload.project_medias
  end

  test "should delete after days in the trash" do
    t = create_team
    pm = create_project_media team: t
    ex = create_explainer team: t
    Sidekiq::Testing.inline! do
      assert_no_difference 'ProjectMedia.count' do
        assert_difference 'Explainer.count', -1 do
          ex = Explainer.find(ex.id)
          ex.trashed = true
          ex.save!
        end
      end
    end
  end

  test "should get alegre models_and_thresholds in hash format" do
    ex = create_explainer
    models_thresholds = Explainer.get_alegre_models_and_thresholds(ex.team_id)
    assert_kind_of Hash, models_thresholds
  end

  test "should set default language when language is not set" do
    ex = create_explainer language: nil
    assert_equal 'en', ex.reload.language
  end

  test "should set author" do
    u = create_user is_admin: true
    User.current = u
    ex = create_explainer
    User.current = nil
    assert_equal u, ex.author
  end

  test "should assign default channel 'manual' for a regular user" do
    t = create_team
    ex = create_explainer(team: t)
    assert_equal "manual", ex.channel
  end

  test "should assign default channel 'api' for a BotUser" do
    bot = create_bot_user(default: true, approved: true)
    t = create_team
    ex = create_explainer(team: t, user: bot, channel: nil)
    assert_equal "api", ex.channel
  end

  test "should allow explicit override of channel" do
    t = create_team
    ex = create_explainer(team: t, channel: "imported")
    assert_equal "imported", ex.channel
  end

  test "should not allow an invalid channel value" do
    t = create_team
    assert_raises(ArgumentError) do
      create_explainer(team: t, channel: "invalid")
    end
  end

  test "should not change channel on update if already set" do
    t = create_team
    ex = create_explainer(team: t, channel: "imported")

    ex.title = "Updated Title"
    ex.save!

    assert_equal "imported", ex.reload.channel
  end
end
