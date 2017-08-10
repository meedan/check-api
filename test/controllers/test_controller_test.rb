require_relative '../test_helper'

class TestControllerTest < ActionController::TestCase
  test "should confirm user by email if in test mode" do
    u = create_user
    assert_nil u.confirmed_at
    get :confirm_user, email: u.email
    assert_response :success
    assert_not_nil u.reload.confirmed_at
  end

  test "should not confirm user by email if not in test mode" do
    Rails.stubs(:env).returns('development')
    u = create_user
    assert_nil u.confirmed_at
    get :confirm_user, email: u.email
    assert_response 400
    assert_nil u.reload.confirmed_at
    Rails.unstub(:env)
  end

  test "should make team public if in test mode" do
    t = create_team private: true
    assert t.private
    get :make_team_public, slug: t.slug
    assert_response :success
    assert !t.reload.private
  end

  test "should not make team public if not in test mode" do
    Rails.stubs(:env).returns('development')
    t = create_team private: true
    assert t.private
    get :make_team_public, slug: t.slug
    assert_response 400
    assert t.reload.private
    Rails.unstub(:env)
  end

  test "should create user if in test mode" do
    assert_difference 'User.count' do
      get :new_user, email: random_email
    end
    assert_response :success
  end

  test "should not create user if not in test mode" do
    Rails.stubs(:env).returns('development')
    assert_no_difference 'User.count' do
      get :new_user, email: random_email
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create team if in test mode" do
    u = create_user
    assert_difference 'Team.count' do
      get :new_team, email: u.email
    end
    assert_response :success
  end

  test "should not create team if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Team.count' do
      get :new_team, email: u.email
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create project if in test mode" do
    t = create_team
    assert_difference 'Project.count' do
      get :new_project, team_id: t.id
    end
    assert_response :success
  end

  test "should not create project if not in test mode" do
    t = create_team
    Rails.stubs(:env).returns('development')
    assert_no_difference 'Project.count' do
      get :new_project, team_id: t.id
    end
    assert_response 400
    Rails.unstub(:env)
  end

  test "should create session if in test mode" do
    u = create_user
    get :new_session, email: u.email
    assert_response :success
  end

  test "should not create session if not in test mode" do
    u = create_user
    Rails.stubs(:env).returns('development')
    get :new_session, email: u.email
    assert_response 400
    Rails.unstub(:env)
  end
end
