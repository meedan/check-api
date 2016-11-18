require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class RegistrationsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::RegistrationsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should create user" do
    assert_difference 'User.count' do
      post :create, api_user: { password: '12345678', password_confirmation: '12345678', email: 't@test.com', login: 'test', name: 'Test' }
      assert_response 401 # needs to confirm before login
    end
  end

  test "should not create user if password is missing" do
    assert_no_difference 'User.count' do
      post :create, api_user: { password_confirmation: '12345678', email: 't@test.com', login: 'test', name: 'Test' }
      assert_response 400
    end
  end

  test "should not create user if password is too short" do
    assert_no_difference 'User.count' do
      post :create, api_user: { password: '123456', password_confirmation: '123456', email: 't@test.com', login: 'test', name: 'Test' }
      assert_response 400
    end
  end

  test "should not create user if password don't match" do
    assert_no_difference 'User.count' do
      post :create, api_user: { password: '12345678', password_confirmation: '12345677', email: 't@test.com', login: 'test', name: 'Test' }
      assert_response 400
    end
  end

  test "should not create user if email is not present" do
    assert_no_difference 'User.count' do
      post :create, api_user: { password: '12345678', password_confirmation: '12345678', email: '', login: 'test', name: 'Test' }
      assert_response 400
    end
  end

  test "should create user if login is not present" do
    assert_difference 'User.count' do
      post :create, api_user: { password: '12345678', password_confirmation: '12345678', email: 't@test.com', login: '', name: 'Test' }
      assert_response 401 # needs to confirm before login
    end
  end

  test "should not create user if name is not present" do
    assert_no_difference 'User.count' do
      post :create, api_user: { password: '12345678', password_confirmation: '12345678', email: 't@test.com', login: 'test', name: '' }
      assert_response 400
    end
  end

  test "should update only a few attributes" do
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: '12345678'
    authenticate_with_user(u)
    post :update, api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: '12345678' }
    assert_response :success
    u = u.reload
    assert_equal 'Bar', u.name
    assert_equal 'test', u.login
    assert_equal 'test', u.token
    assert_equal 'bar@test.com', u.email
  end

  test "should not update account if not logged in" do
    post :update, api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: '12345678' }
    assert_response 401
  end

  test "should not update account" do
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: '12345678'
    authenticate_with_user(u)
    post :update, api_user: { name: 'Bar', login: 'bar', token: 'bar', email: 'bar@test.com', current_password: '12345678', password: '123', password_confirmation: '123' }
    assert_response 400
    u = u.reload
  end

  test "should destroy account" do
    u = create_user name: 'Foo', login: 'test', token: 'test', email: 'foo@test.com', password: '12345678'
    authenticate_with_user(u)
    assert_difference 'User.count', -1 do
      delete :destroy
    end
    assert_response :success
  end

  test "should not destroy account if not logged in" do
    assert_no_difference 'User.count' do
      delete :destroy
    end
    assert_response 401
  end
end
