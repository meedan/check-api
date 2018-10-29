require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')
require 'sidekiq/testing'

class TeamImportTest < ActiveSupport::TestCase
  def setup
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
    super
    create_verification_status_stuff
    create_translation_status_stuff(false)
    create_bot name: 'Check Bot'
    @team = create_team
    @user = create_user is_admin: true
    create_team_user team: @team, user: @user, role: 'contributor'
    @p = create_project team: @team
    @spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
    @spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    session = GoogleDrive::Session.from_service_account_key(CONFIG['google_credentials_path'])
    @worksheet = session.spreadsheet_by_key(@spreadsheet_id).worksheets[0]
  end

  def teardown
    for row in 0..@worksheet.num_rows
      @worksheet.list[row].clear
    end
    @worksheet.save
  end

  test "should get id from spreadsheet url" do
    spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0"
    assert_equal '1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo', Team.spreadsheet_id(spreadsheet_url)
  end

  test "should return nil if not a valid spreadsheet url" do
    variations = %w(
      https://example.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0
      https://docs.google.com/spreadsheets/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/
      https://docs.google.com/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/
    )
    with_current_user_and_team(@user, @team) {
      variations.each do |url|
        assert_nil Team.spreadsheet_id(url)
        assert_raise RuntimeError do
          Team.import_spreadsheet_in_background(url, @team.id, @user.id)
        end
      end
    }
  end

  test "handle error when failing authentication on Google Drive" do
    credentials_path = CONFIG['google_credentials_path']
    invalid_credentials = JSON.parse(File.read(credentials_path))
    invalid_credentials['client_email'] = 'invalid@email.com'
    File.open('/tmp/invalid.json', "w+") do |f|
      f.write(invalid_credentials.to_json)
    end
    CONFIG['google_credentials_path'] = '/tmp/invalid.json'
    spreadsheet_url = 'https://docs.google.com/spreadsheets/d/1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo/edit#gid=0'
    with_current_user_and_team(@user, @team) {
      assert_raise RuntimeError do
        Team.import_spreadsheet_in_background(spreadsheet_url, @team.id, @user.id)
      end
    }
    CONFIG['google_credentials_path'] = credentials_path
  end

  test "should raise error if spreadsheet id was not found" do
    spreadsheet_url = "https://docs.google.com/spreadsheets/d/1lyxshfgvdgvjgfvjhgvjhgfvjhgdvjgvjhgdvj_Z9jo/edit#gid=0"
    with_current_user_and_team(@user, @team) {
      assert_raise RuntimeError do
        Team.import_spreadsheet_in_background(spreadsheet_url, @team.id, @user.id)
      end
    }
  end

  test "should rescue when any error raise when try to get spreadsheet" do
    GoogleDrive::Session.stubs(:from_service_account_key).with(CONFIG['google_credentials_path']).returns(RuntimeError)
    with_current_user_and_team(@user, @team) {
      assert_raise RuntimeError do
        Team.import_spreadsheet_in_background(@spreadsheet_url, @team.id, @user.id)
      end
    }
    GoogleDrive::Session.unstub(:from_service_account_key)
  end

  test "should get id from the valid projects when import from spreadsheet" do
    projects = []
    projects << invalid_domain = "http://invalid-domain/#{@team.slug}/project/1"
    projects << invalid_team = "#{CONFIG['checkdesk_client']}/other-team/project/2"
    (3..4).each do |id|
      projects << "#{CONFIG['checkdesk_client']}/#{@team.slug}/project/#{id}"
    end
    projects = projects.join(' , ')
    assert_equal [3, 4], @team.send(:get_projects, projects)
  end

  test "should import from spreadsheet in background" do
    with_current_user_and_team(@user, @team) {
      assert_nothing_raised do
        Team.import_spreadsheet_in_background(@spreadsheet_url, @team.id, @user.id)
      end
    }
  end

  test "should return blank user from spreadsheet" do
    data = { item: 'https://www.facebook.com/APNews/photos/pb.249655421622.-2207520000.1534711057./10155603019006623/?type=3&theater', projects: 'https://checkmedia.org/meedanteam/project/1000' }
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match(I18n.t("team_import.blank_user"), result[row].join(', '))
    }
  end

  test "should return invalid user and project errors from spreadsheet" do
    data1 = { item: 'A claim', user: 'https://qa.checkmedia.org/check/user/16', projects: 'https://checkmedia.org/meedanteam/project/1000,https://checkmedia.org/meedanteam/project/1001' }
    row1 = add_data_on_spreadsheet(data1)
    data2 = data1.merge({user: 'http://yahoo.com', projects: 'https://checkmedia.org/meedanteam/project/1000' })
    row2 = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match("#{I18n.t("team_import.invalid_user", { user: data1[:user] })}, "\
                   "#{I18n.t("team_import.invalid_project", { project: data1[:projects].split(',')[0] })}, "\
                   "#{I18n.t("team_import.invalid_project", { project: data1[:projects].split(',')[1] })}",
        result[row1].join(', ')
      )
      assert_match("#{I18n.t("team_import.invalid_user", { user: data2[:user] })}, "\
                   "#{I18n.t("team_import.invalid_project", { project: data2[:projects] })}",
        result[row2].join(', ')
      )
    }
  end

  test "should return blank project error from spreadsheet" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url }
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match(I18n.t("team_import.blank_project"), result[row].join(', '))
    }
  end

  test "should show url when import from spreadsheet a duplicated media" do
    url = 'https://ca.ios.ba/'
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)

    m = create_media url: url
    pm = create_project_media media: m, project: @p
    create_bot name: 'Check Bot'
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: url, user: user_url, projects: @p.url }
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_equal pm.full_url, result[row].join(', ')
    }
  end

  test "should add as note column 'Item note'" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url, projects: @p.url, annotator: user_url, note1: 'A note', note2: 'Other note' }
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      pm = Media.find_by_quote(data[:item]).project_medias.first
      assert_equal ['A note', 'Other note'], pm.comments.map(&:text).sort
      assert_equal pm.full_url, result[row].join(', ')
    }
  end

  test "should not add note if annotator is not valid" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    invalid_annotator = 'some annotator that is invalid'
    data1 = { item: 'A claim', user: user_url, projects: @p.url, annotator: invalid_annotator, note1: 'A note' }
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row_with_invalid_annotator = add_data_on_spreadsheet(data1)

    user2 = create_user is_admin: true
    user2_url = "#{CONFIG['checkdesk_client']}/check/user/#{user2.id}"
    data2 = data1.merge({ item: 'Other claim', annotator: user2_url})
    row_with_valid_annotator = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      pm1 = Media.find_by_quote(data1[:item]).project_medias.first
      assert pm1.comments.empty?
      assert_match(I18n.t("team_import.invalid_annotator", { user: invalid_annotator }), result[row_with_invalid_annotator].join(', '))

      pm2 = Media.find_by_quote(data2[:item]).project_medias.first
      assert_equal ['A note'], pm2.comments.map(&:text)
      assert_no_match(I18n.t("team_import.invalid_annotator", { user: invalid_annotator }), result[row_with_valid_annotator].join(', '))
    }
  end

  test "should add user as annotator if annotator is blank" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url, projects: @p.url, note1: 'A note' }
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      pm = Media.find_by_quote(data[:item]).project_medias.first
      assert_equal [@user.id], pm.comments.map(&:annotator_id)
      assert_no_match(I18n.t("team_import.invalid_annotator"), result[row].join(', '))
    }
  end

  test "should not assign if user on assigned to is not valid" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    invalid_assignee = 'Some assignee that is invalid'
    data1 = { item: 'A claim', user: user_url, projects: @p.url, assigned_to: invalid_assignee }
    row_with_invalid_assignee = add_data_on_spreadsheet(data1)
    data2 = data1.merge({item: 'Other claim', assigned_to: user_url})
    row_with_valid_assignee = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      pm1 = Media.find_by_quote(data1[:item]).project_medias.first
      assert_equal 0, pm1.last_status_obj.assignments.size
      assert_match pm1.full_url, result[row_with_invalid_assignee].join(', ')
      assert_match I18n.t("team_import.invalid_assignee", { user: invalid_assignee }), result[row_with_invalid_assignee].join(', ')

      pm2 = Media.find_by_quote(data2[:item]).project_medias.first
      assert_equal pm2.full_url, result[row_with_valid_assignee].join(', ')
      assert_equal [@user], pm2.last_status_obj.assigned_users
    }
  end

  test "should not try to add duplicated tags" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url, projects: @p.url, tags: 'tag1, tag2' }
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)

      pm = Media.find_by_quote(data[:item]).project_medias.first
      assert_equal pm.full_url, result[row].join(', ')
      assert_equal ['tag1', 'tag2'], pm.annotations('tag').map(&:tag_text).sort

      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_equal pm.full_url, result[row].join(', ')

    }
  end

  test "should rescue when raise error on item creation" do
    ProjectMedia.stubs(:create!).raises(RuntimeError.new('error'))

    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url, projects: @p.url }
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_equal 'error', result[row].join(', ')
    }
    ProjectMedia.unstub(:create!)
  end

  test "should show status error if not valid" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    invalid_status = 'Some status that is invalid'
    data1 = { item: 'A claim', user: user_url, projects: @p.url, status: invalid_status }
    row_with_invalid_status = add_data_on_spreadsheet(data1)

    valid_status = Workflow::Workflow.options(ProjectMedia.new, ProjectMedia.new.default_project_media_status_type)['statuses'].find { |s| s['completed'].to_i == 1}['id']
    data2 = data1.merge({ item: 'Other claim', status: valid_status })
    row_with_valid_status = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)

      pm1 = Media.find_by_quote(data1[:item]).project_medias.first
      assert_match("#{pm1.full_url}, #{I18n.t("team_import.invalid_status", { status: invalid_status })}", result[row_with_invalid_status].join(', '))
      assert_not_equal invalid_status, pm1.last_status

      pm2 = Media.find_by_quote(data2[:item]).project_medias.first
      assert_equal pm2.full_url, result[row_with_valid_status].join(', ')
      assert_equal valid_status, pm2.last_status
    }
  end

  test "should add tasks" do
    at = create_annotation_type annotation_type: 'task_response_free_text', label: 'Task'
    ft1 = create_field_type field_type: 'text_field', label: 'Text Field'
    ft2 = create_field_type field_type: 'task_reference', label: 'Task Reference'
    create_field_instance annotation_type_object: at, name: 'response_free_text', label: 'Response', field_type_object: ft1
    create_field_instance annotation_type_object: at, name: 'task_free_text', label: 'Task', field_type_object: ft2

    create_team_task team_id: @team.id, label: 'What?'
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = { item: 'A claim', user: user_url, projects: @p.url, task1: 'A text' }
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)

      pm = Media.find_by_quote(data[:item]).project_medias.first
      assert_equal pm.full_url, result[row].join(', ')
      assert_equal ['A text'], pm.annotations('task').map(&:first_response).sort
    }
  end

  protected

  def add_data_on_spreadsheet(data)
    template = { item: 2, user: 3, projects: 4, assigned_to: 5, tags: 6, status: 7, annotator: 8, note1: 9, note2: 10, task1: 11, task2: 12 }
    row = @worksheet.num_rows + 1
    data.each_pair do |column, value|
      @worksheet[row, template[column]] = value
    end
    @worksheet.save
    row
  end
end
