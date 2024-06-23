require_relative '../test_helper'

class ExplainerItemTest < ActiveSupport::TestCase
  def setup
    @t = create_team
    @pm = create_project_media(team: @t, media: create_claim_media(quote: 'Test'))
    @ex = create_explainer(team: @t)
  end

  def teardown
  end

  test "should create explainer item" do
    assert_difference 'ExplainerItem.count' do
      ExplainerItem.create! explainer: @ex, project_media: @pm
    end
  end

  test "should be associated with explainers" do
    assert_difference 'ExplainerItem.count' do
      @ex.project_medias << @pm
    end
    assert_equal 1, @ex.project_medias.count
  end

  test "should be associated with items" do
    assert_difference 'ExplainerItem.count' do
      @pm.explainers << @ex
    end
    assert_equal 1, @pm.explainers.count
  end

  test "should not create explainer item without mandatory fields" do
    ei = ExplainerItem.new
    assert_not ei.valid?
    ei = ExplainerItem.new project_media: @pm
    assert_not ei.valid?
    ei = ExplainerItem.new explainer: @ex
    assert_not ei.valid?
    ei = ExplainerItem.new project_media: @pm, explainer: @ex
    assert ei.valid?
  end

  test "should not create associate explainer and item from different workspaces" do
    t1 = create_team
    e1 = create_explainer team: t1
    pm1 = create_project_media team: t1
    t2 = create_team
    e2 = create_explainer team: t2
    pm2 = create_project_media team: t2
    assert ExplainerItem.new(project_media: pm1, explainer: e1).valid?
    assert ExplainerItem.new(project_media: pm2, explainer: e2).valid?
    assert_not ExplainerItem.new(project_media: pm1, explainer: e2).valid?
    assert_not ExplainerItem.new(project_media: pm2, explainer: e1).valid?
  end

  test "should have permission to create explainer item" do
    t1 = create_team
    u1 = create_user
    create_team_user user: u1, team: t1
    e1 = create_explainer team: t1
    pm1 = create_project_media team: t1

    t2 = create_team
    u2 = create_user
    create_team_user user: u2, team: t2
    e2 = create_explainer team: t2
    pm2 = create_project_media team: t2

    with_current_user_and_team u1, t1 do
      assert_difference 'ExplainerItem.count' do
        pm1.explainers << e1
      end
      assert_no_difference 'ExplainerItem.count' do
        assert_raises RuntimeError do # Permission error
          pm2.explainers << e2
        end
      end
    end

    with_current_user_and_team u2, t2 do
      assert_no_difference 'ExplainerItem.count' do
        assert_raises RuntimeError do # Permission error
          pm1.explainers << e1
        end
      end
      assert_difference 'ExplainerItem.count' do
        pm2.explainers << e2
      end
    end
  end
end
