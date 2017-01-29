require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ConfirmationsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::ConfirmationsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should not confirm account if client host is not recognized" do
    u = create_user provider: ''
    get :show, confirmation_token: u.confirmation_token, client_host: 'http://anotherhost:3333'
    assert_response 400
    assert_nil u.reload.confirmed_at
  end

  test "should not confirm account if token is invalid" do
    u = create_user provider: ''
    get :show, confirmation_token: u.confirmation_token.reverse, client_host: 'http://localhost:3333'
    assert_redirected_to 'http://localhost:3333/user/unconfirmed'
    assert_nil u.reload.confirmed_at
  end

  test "should confirm account" do
    u = create_user provider: ''
    get :show, confirmation_token: u.confirmation_token, client_host: 'http://localhost:3333'
    assert_redirected_to 'http://localhost:3333/user/confirmed'
    assert_not_nil u.reload.confirmed_at
  end

  test "should confirm account for new user" do
    u1 = create_user provider: ''
    User.current = User.new
    assert_nothing_raised do
      get :show, confirmation_token: u1.confirmation_token, client_host: 'http://test.localhost:3333'
    end
    User.current = nil
  end
end
