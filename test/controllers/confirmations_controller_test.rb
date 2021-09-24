require_relative '../test_helper'

class ConfirmationsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::ConfirmationsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should not confirm account if client host is not recognized" do
    u = create_user confirm: false
    get :show, params: { confirmation_token: u.confirmation_token, client_host: 'http://anotherhost:3333' }
    assert_response 400
    assert_nil u.reload.confirmed_at
  end

  test "should not confirm account if token is invalid" do
    u = create_user confirm: false
    get :show, params: { confirmation_token: u.confirmation_token.reverse, client_host: CheckConfig.get('checkdesk_client') }
    assert_redirected_to "#{CheckConfig.get('checkdesk_client')}/check/user/confirm/unconfirmed"
    assert_nil u.reload.confirmed_at
  end

  test "should redirect to already confirmed page if user is valid" do
    u = create_user
    assert_not_nil u.reload.confirmed_at
    get :show, params: { confirmation_token: u.confirmation_token, client_host: CheckConfig.get('checkdesk_client') }
    assert_redirected_to "#{CheckConfig.get('checkdesk_client')}/check/user/confirm/already-confirmed"
  end

  test "should confirm account" do
    u = create_user confirm: false
    get :show, params: { confirmation_token: u.confirmation_token, client_host: CheckConfig.get('checkdesk_client') }
    assert_redirected_to "#{CheckConfig.get('checkdesk_client')}/check/user/confirm/confirmed"
    assert_not_nil u.reload.confirmed_at
  end

  test "should confirm account for new user" do
    u1 = create_user confirm: false
    User.current = User.new
    assert_nothing_raised do
      get :show, params: { confirmation_token: u1.confirmation_token, client_host: 'http://test.localhost:3333' }
    end
    User.current = nil
  end
end
