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
end
