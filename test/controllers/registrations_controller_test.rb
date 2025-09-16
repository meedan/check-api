require_relative '../test_helper'

class RegistrationsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::RegistrationsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
    User.current = nil
    Team.current = nil
  end

  def teardown
    super
    User.current = nil
    Team.current = nil
  end

  test "should create user" do
    p1 = random_complex_password
    assert_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 't@test.com', login: 'test', name: 'Test' } }
      assert_response 401 # needs to confirm before login
    end
  end

  test "should create user if invited" do
    t = create_team
    u = create_user
    email = 'test@local.com'
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      members = [{role: 'collaborator', email: email}]
      User.send_user_invitation(members)
    end
    User.current = Team.current = nil
    p1 = random_complex_password
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: email, login: 'test', name: 'Test' } }
      assert_response 401
    end
  end

  test "should create user if confirmed" do
    p1 = random_complex_password
    User.any_instance.stubs(:confirmation_required?).returns(false)
    assert_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 't@test.com', login: 'test', name: 'Test' } }
      assert_response 401
    end
    User.any_instance.unstub(:confirmation_required?)
  end

  test "should not create user if password is missing" do
    p1 = random_complex_password
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password_confirmation: p1, email: 't@test.com', login: 'test', name: 'Test' } }
      assert_response 401
    end
  end

  test "should not create user if password is too short" do
    p1 = '1234'
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 't@test.com', login: 'test', name: 'Test' } }
      assert_response 401
    end
  end

  test "should not create user if password don't match" do
    p1 = random_complex_password
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: random_complex_password, password_confirmation: random_complex_password, email: 't@test.com', login: 'test', name: 'Test' } }
      assert_response 401
    end
  end

  test "should not create user if email is not present" do
    p1 = random_complex_password
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: '', login: 'test', name: 'Test' } }
      assert_response 401
    end
  end

  test "should create user if login is not present" do
    p1 = random_complex_password
    assert_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 't@test.com', login: '', name: 'Test' } }
      assert_response 401 # needs to confirm before login
    end
  end

  test "should not create user if name is not present" do
    p1 = random_complex_password
    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 't@test.com', login: 'test', name: '' } }
      assert_response 401
    end
  end

  test "should update only a few attributes" do
    p1 = random_complex_password
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: p1
    authenticate_with_user(u)
    post :update, params: { api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: p1 } }
    assert_response :success
    u = u.reload
    assert_equal 'Bar', u.name
    assert_equal 'test', u.login
    assert_equal 'test', u.token
    assert_empty u.email
    assert_equal 'bar@test.com', u.unconfirmed_email
  end

  test "should not update account if not logged in" do
    p1 = random_complex_password
    post :update, params: { api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: p1 } }
    assert_response 401
  end

  test "should not update account" do
    p1 = random_complex_password
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: p1
    authenticate_with_user(u)
    post :update, params: { api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: p1, password: '123', password_confirmation: '123' } }
    assert_response 400
    u = u.reload
  end

  test "should destroy account" do
    p1 = random_complex_password
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: p1
    authenticate_with_user(u)
    assert_difference 'User.count', -1 do
      delete :destroy, params: {}
    end
    assert_response :success
  end

  test "should not destroy account if not logged in" do
    assert_no_difference 'User.count' do
      delete :destroy, params: {}
    end
    assert_response 401
  end

  test "should return generic response in case of error when registering using an existing email" do
    existing_user = create_user(email: 'existing@test.com')
    p1 = random_complex_password

    assert_no_difference 'User.count' do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: existing_user.email, login: 'test', name: 'Test' } }
      assert_response 401
      assert_equal 'Please check your email. If an account with that email doesn’t exist, you should have received a confirmation email. If you don’t receive a confirmation e-mail, try to reset your password or get in touch with our support.', JSON.parse(response.parsed_body).dig("errors", 0, "message")
    end
  end

  test "should return generic response when registering with non-existing email" do
    p1 = random_complex_password

    assert_difference 'User.count', 1 do
      post :create, params: { api_user: { password: p1, password_confirmation: p1, email: 'non_existing@test.com', login: 'test', name: 'Test' } }
      assert_response 401
      assert_equal 'Please check your email. If an account with that email doesn’t exist, you should have received a confirmation email. If you don’t receive a confirmation e-mail, try to reset your password or get in touch with our support.', JSON.parse(response.parsed_body).dig("errors", 0, "message")
    end
  end
end
