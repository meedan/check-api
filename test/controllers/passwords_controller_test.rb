require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class PasswordsControllerTest < ActionController::TestCase
  def setup
    super
    @controller = Api::V1::PasswordsController.new
    @request.env["devise.mapping"] = Devise.mappings[:api_user]
  end

  test "should display page to reset password" do
    u = create_user provider: ''
    token = u.send_reset_password_instructions
    get :edit, reset_password_token: token
    assert_response 200
    assert_template 'devise/passwords/edit.html.erb'
  end

  test "should redirect user if reset password url has no token" do
    u = create_user provider: ''
    get :edit
    assert_response 302
  end

  test "should not update password if password not valid" do
    u = create_user provider: ''
    token = u.send_reset_password_instructions
    put :update, api_user: { reset_password_token: token, password: '1234', password_confirmation: '1234'}

    assert_response 200
    assert_template 'devise/passwords/edit.html.erb'
  end

  test "should not update password if password and confirmation don't match" do
    u = create_user provider: ''
    token = u.send_reset_password_instructions
    put :update, api_user: { reset_password_token: token, password: '12345678', password_confirmation: '87654321'}
    assert_response 200
    assert_template 'devise/passwords/edit.html.erb'
  end

  test "should update password" do
    u = create_user provider: ''
    token = u.send_reset_password_instructions
    put :update, api_user: { reset_password_token: token, password: '12345678', password_confirmation: '12345678'}
    assert_response 200
    assert_equal 'success', JSON.parse(@response.body)['type']
    assert_template nil
  end
end
