require_relative '../test_helper'

class AdminIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/)
    @user = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com', provider: ''
    @user.confirm
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
    sign_in @user
    get '/admin'
    assert_redirected_to '/403.html'
    sign_out @user

    @user.is_admin = true
    @user.save!
    sign_in @user
    get '/admin'
    assert_response :success
  end

  test "should not access Admin UI if user has no role" do
    assert_nil @user.role

    sign_in @user

    get '/admin'
    assert_redirected_to '/403.html'
  end

  test "should access admin UI dashboard if admin" do
    @user.is_admin = true
    @user.save!
    sign_in @user
    get '/admin/dashboard'
    assert_response :success
  end

  %w(contributor journalist editor).each do |role|
    test "should not access admin UI if team #{role}" do
      Team.stubs(:current).returns(nil)
      create_team_user user: @user, role: role
      sign_in @user
      get '/admin'
      assert_redirected_to '/403.html'
      sign_out @user
    end
  end

  test "should access admin UI if team owner" do
    Team.stubs(:current).returns(nil)
    create_team_user user: @user, role: 'owner'
    sign_in @user

    get '/admin'
    assert_response :success
  end

  test "should access new project page" do
    sign_in @admin_user

    get '/admin/project/new'
    assert_response :success
  end

  test "should show link to send reset password email to admin" do
    sign_in @admin_user

    get "/admin/user/#{@admin_user.id}/"

    assert_select "a[href=?]", "#{request.base_url}/admin/user/#{@admin_user.id}/send_reset_password_email"
  end

  test "should admin send reset password email and redirect" do
    sign_in @admin_user

    get "/admin/user/#{@admin_user.id}/send_reset_password_email"
    assert_redirected_to '/admin/user'
  end

  test "should admin access User page" do
    sign_in @admin_user

    get "/admin/user/#{@user.id}/edit"
    assert_response :success
  end

  test "should access User page with setting with json error" do
    sign_in @admin_user
    @user.set_languages('invalid_json')
    @user.save(:validate => false)
    get "/admin/user/#{@user.id}/edit"
    assert_response :success
  end

  test "should edit and save User with yaml field" do
    sign_in @admin_user

    put "/admin/user/#{@user.id}/edit", user: { languages: "[{'id': 'en','title': 'English'}]" }
    assert_redirected_to '/admin/user'
    assert_equal [{"id" => "en", "title" => "English"}], @user.reload.get_languages
  end

  test "should edit and save suggested tags on Team" do
    sign_in @admin_user

    put "/admin/team/#{@team.id}/edit", team: { suggested_tags: "one tag, other tag" }
    assert_redirected_to '/admin/team'
    assert_equal "one tag, other tag", @team.reload.get_suggested_tags
  end

  test "should show link to export data of a project" do
    @user.is_admin = true
    @user.save!

    sign_in @user

    get "/admin/project/#{@project.id}/"

    assert_select "a[href=?]",
    "#{request.base_url}/admin/project/#{@project.id}/export_project"
  end

  test "should download exported data of a project" do
    @user.is_admin = true
    @user.save!

    sign_in @user

    get "/admin/project/#{@project.id}/export_project"
    assert_equal "text/csv", @response.headers['Content-Type']
    assert_match(/attachment; filename=\"#{@project.team.slug}_#{@project.title.parameterize}_.*\.csv\"/, @response.headers['Content-Disposition'])
    assert_response :success
  end

end
