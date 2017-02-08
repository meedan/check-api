require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AdminIntegrationTest < ActionDispatch::IntegrationTest

  def setup
    @user = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com', provider: ''
    @user.confirm
  end

  test "should access admin UI if admin" do
    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    assert_raise CanCan::AccessDenied do
      get '/admin'
    end

    @user.is_admin = true
    @user.save!

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    assert_nothing_raised CanCan::AccessDenied do
      get '/admin'
    end
  end

  test "should not access Admin UI if user has no role" do
    assert_equal nil, @user.role

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    assert_raise CanCan::AccessDenied do
      get '/admin'
    end
  end

  %w(contributor journalist editor).each do |role|
    test "should not access admin UI if team #{role}" do
      tu = create_team_user user: @user, role: role
      post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

      assert_raise CanCan::AccessDenied do
        get '/admin'
      end
    end
  end

  test "should access admin UI if team owner" do
    tu = create_team_user user: @user, role: 'owner'
    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    assert_nothing_raised CanCan::AccessDenied do
      get '/admin'
    end
  end

end
