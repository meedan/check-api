require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AdminIntegrationTest < ActionDispatch::IntegrationTest

  def setup
    @user = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com', provider: ''
    @user.confirm
  end

  test "should redirect to root if not logged user access admin UI" do
    get '/admin'
    assert_redirected_to '/'
  end

  test "should access admin UI if admin" do
    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get '/admin'
    assert_redirected_to '/403.html'

    @user.is_admin = true
    @user.save!

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get '/admin'
    assert_response :success
  end

  test "should not access Admin UI if user has no role" do
    assert_equal nil, @user.role

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get '/admin'
    assert_redirected_to '/403.html'
  end

  %w(contributor journalist editor).each do |role|
    test "should not access admin UI if team #{role}" do
      Team.stubs(:current).returns(nil)
      create_team_user user: @user, role: role
      post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }
      get '/admin'
      assert_redirected_to '/403.html'
    end
  end

  test "should access admin UI if team owner" do
    Team.stubs(:current).returns(nil)
    create_team_user user: @user, role: 'owner'
    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get '/admin'
    assert_response :success
  end

  test "should access new project page" do
    @user.is_admin = true
    @user.save!

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get '/admin/project/new'
    assert_response :success
  end

end
