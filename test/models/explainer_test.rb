require_relative '../test_helper'

class ExplainerTest < ActiveSupport::TestCase
  def setup
    Explainer.delete_all
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
end
