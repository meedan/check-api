require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AdminIntegrationTest < ActionDispatch::IntegrationTest

  def setup
    @admin_user = create_user login: 'admin_user', password: '12345678', password_confirmation: '12345678', email: 'admin@test.com', provider: ''
    @admin_user.confirm
    @admin_user.is_admin = true
    @admin_user.save!

    @project = create_project user: @user
    @team = create_team
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
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    get '/admin/project/new'
    assert_response :success
  end

  test "should show link to send reset password email" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    get "/admin/user/#{@admin_user.id}/"

    assert_select "a[href=?]", "#{request.base_url}/admin/user/#{@admin_user.id}/send_reset_password_email"
  end

  test "should send reset password email and redirect" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    get "/admin/user/#{@admin_user.id}/send_reset_password_email"
    assert_redirected_to '/admin/user'
  end

  test "should access User page" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    get "/admin/user/#{@user.id}/edit"
    assert_response :success
  end

  test "should access User page with setting with json error" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }
    @user.set_languages('invalid_json')
    @user.save
    get "/admin/user/#{@user.id}/edit"
    assert_response :success
  end

  test "should edit and save User with yaml field" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    put "/admin/user/#{@user.id}/edit", user: { languages: "[{'id': 'en','title': 'English'}]" }
    assert_redirected_to '/admin/user'
    assert_equal [{"id" => "en", "title" => "English"}], @user.reload.get_languages
  end

  test "should edit and save suggested tags on Team" do
    post '/api/users/sign_in', api_user: { email: @admin_user.email, password: @admin_user.password }

    put "/admin/team/#{@team.id}/edit", team: { suggested_tags: "one tag, other tag" }
    assert_redirected_to '/admin/team'
    assert_equal "one tag, other tag", @team.reload.get_suggested_tags
  end

  test "should show link to export data of a project" do
    @user.is_admin = true
    @user.save!

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get "/admin/project/#{@project.id}/"

    assert_select "a[href=?]",
    "#{request.base_url}/admin/project/#{@project.id}/export_project"
  end

  test "should download exported data of a project" do
    @user.is_admin = true
    @user.save!

    post '/api/users/sign_in', api_user: { email: @user.email, password: @user.password }

    get "/admin/project/#{@project.id}/export_project"
    assert_equal "text/csv", @response.headers['Content-Type']
    assert_match(/attachment; filename=\"#{@project.team.slug}_#{@project.title.parameterize}_.*\.csv\"/, @response.headers['Content-Disposition'])
    assert_response :success
  end

end
