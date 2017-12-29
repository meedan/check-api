require_relative '../test_helper'

class AdminIntegrationTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/)
    @team = create_team
    Team.stubs(:current).returns(@team)
    @user = create_user login: 'test', password: '12345678', password_confirmation: '12345678', email: 'test@test.com', provider: ''
    @user.confirm
    @admin_user = create_user login: 'admin_user', password: '12345678', password_confirmation: '12345678', email: 'admin@test.com', provider: ''
    @admin_user.confirm
    @admin_user.is_admin = true
    @admin_user.save!

    @project = create_project user: @user, team: @team
  end

  def teardown
    super
    Team.unstub(:current)
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
      Team.unstub(:current)
    end
  end

  test "should access admin UI if team owner" do
    Team.stubs(:current).returns(nil)
    create_team_user user: @user, role: 'owner'
    sign_in @user

    get '/admin'
    assert_response :success
    Team.unstub(:current)
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

  test "should edit a team as team owner" do
    sign_in @user
    team_2 = create_team
    create_team_user team: team_2, user: @user, role: 'owner'
    create_team_user team: @team, user: @user, role: 'owner'
    put "/admin/team/#{team_2.id}/edit", team: { hide_names_in_embeds: "1" }
    assert_redirected_to '/admin/team'
    assert_equal "1", team_2.reload.get_hide_names_in_embeds
  end

  test "should handle error on edition of a team" do
    sign_in @user
    team = create_team
    create_team_user team: team, user: @user, role: 'owner'
    Team.any_instance.stubs(:save).returns(false)
    get "/admin/team/#{team.id}/edit"
    put "/admin/team/#{team.id}/edit", team: { hide_names_in_embeds: "1" }
    assert_not_equal "1", team.reload.get_hide_names_in_embeds
    Team.any_instance.unstub(:save)
  end

  test "should delete a project as team owner" do
    sign_in @user
    create_team_user team: @team, user: @user, role: 'owner'
    team_2 = create_team
    create_team_user team: team_2, user: @user, role: 'owner'
    project_2 = create_project user: @user, team: team_2
    m = create_valid_media
    pm = create_project_media project: project_2, media: m
    create_task annotator: @user, annotated: pm
    create_comment annotated: pm
    s = create_status status: 'verified', annotated: pm
    get "/admin/project/#{project_2.id}/delete"
    RequestStore.store[:disable_es_callbacks] = true
    delete "/admin/project/#{project_2.id}/delete"

    assert_redirected_to '/admin/project'
    assert_raises ActiveRecord::RecordNotFound do
      Project.find(project_2.id)
    end
    RequestStore.store[:disable_es_callbacks] = false
  end

  test "should handle error on deletion of a project" do
    sign_in @user
    team = create_team
    create_team_user team: team, user: @user, role: 'owner'
    project = create_project user: @user, team: team
    Project.any_instance.stubs(:destroy).returns(false)
    delete "/admin/project/#{project.id}/delete"
    assert_nothing_raised do
      Project.find(project.id)
    end

    Project.any_instance.unstub(:destroy)
  end

  test "should delete tasks of a team" do
    sign_in @user
    team = create_team
    value =  [{ label: 'A task', type: 'free_text', description: '', projects: [], options: '[]'}]
    team.set_checklist(value)
    team.save!

    assert !team.get_checklist.empty?
    create_team_user team: team, user: @user, role: 'owner'
    get "/admin/team/#{team.id}/delete_tasks"
    put "/admin/team/#{team.id}/delete_tasks"
    assert_equal [], Team.find(team.id).checklist
  end

  test "should handle error on deletion of a team tasks" do
    sign_in @admin_user
    team = create_team
    value =  [{ label: 'A task', type: 'free_text', description: '', projects: [], options: '[]'}]
    team.set_checklist(value)
    team.save!

    Team.any_instance.stubs(:save).returns(false)
    put "/admin/team/#{team.id}/delete_tasks"
    assert !team.get_checklist.empty?
    Team.any_instance.unstub(:save)
  end

end
