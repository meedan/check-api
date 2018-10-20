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
    [0, 1].each { |i| @worksheet.list[i].clear }
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
    data = ['https://www.facebook.com/APNews/photos/pb.249655421622.-2207520000.1534711057./10155603019006623/?type=3&theater', '', 'https://checkmedia.org/meedanteam/project/1000']
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match(/User is blank/, result[row].join(', '))
    }
  end

  test "should return invalid user and project errors from spreadsheet" do
    data1 = ['This is an example of a claim', 'https://qa.checkmedia.org/check/user/16', 'https://checkmedia.org/meedanteam/project/1000,https://checkmedia.org/meedanteam/project/1001']
    row1 = add_data_on_spreadsheet(data1)
    data2 = ['This is an example of a claim', 'http://yahoo.com', 'https://checkmedia.org/meedanteam/project/1000']
    row2 = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match(/Invalid user: .*Invalid project: .*Invalid project: /, result[row1].join(', '))
      assert_match(/Invalid user: .*Invalid project: /, result[row2].join(', '))
    }
  end

  test "should return blank project error from spreadsheet" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = ['A claim', user_url, '']
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match(/Project is blank/, result[row].join(', '))
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
    data = [url, "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}", @p.url]
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_equal pm.full_url, result[row].join(', ')
    }
  end

  test "should not add note if annotator is not valid" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data1 = ['A claim', user_url, @p.url, 'A note', 'invalid annotator']
    spreadsheet_id = "1lyxWWe9rRJPZejkCpIqVrK54WUV2UJl9sR75W5_Z9jo"
    row_with_invalid_annotator = add_data_on_spreadsheet(data1)
    data2 = ['Other claim', user_url, @p.url, 'A note', user_url]
    row_with_valid_annotator = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_match('Invalid annotator', result[row_with_invalid_annotator].join(', '))
      assert_no_match('Invalid annotator', result[row_with_valid_annotator].join(', '))
    }
  end

  test "should not assign if user on assigned to is not valid" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data1 = ['A claim', user_url, @p.url, '', '', 'invalid assigned']
    row_with_invalid_assignee = add_data_on_spreadsheet(data1)
    data2 = ['Other claim', user_url, @p.url, '', '', user_url]
    row_with_valid_assignee = add_data_on_spreadsheet(data2)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      pm1 = Media.find_by_quote(data1[0]).project_medias.first
      assert_nil pm1.last_status_obj.assigned_to_id
      assert_match pm1.full_url, result[row_with_invalid_assignee].join(', ')
      assert_match /Invalid assignee/, result[row_with_invalid_assignee].join(', ')

      pm2 = Media.find_by_quote(data2[0]).project_medias.first
      assert_equal pm2.full_url, result[row_with_valid_assignee].join(', ')
      assert_equal @user.id, pm2.last_status_obj.assigned_to_id
    }
  end

  test "should not try to add duplicated tags" do
    user_url = "#{CONFIG['checkdesk_client']}/check/user/#{@user.id}"
    data = ['A claim', user_url, @p.url, '', '', '', 'tag1, tag2']
    row = add_data_on_spreadsheet(data)

    with_current_user_and_team(@user, @team) {
      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)

      pm = Media.find_by_quote(data[0]).project_medias.first
      assert_equal pm.full_url, result[row].join(', ')
      assert_equal ['tag1', 'tag2'], pm.annotations('tag').map(&:tag_text).sort

      result = @team.import_spreadsheet(@spreadsheet_id, @user.id)
      assert_equal pm.full_url, result[row].join(', ')

    }
  end

  protected

  def add_data_on_spreadsheet(data)
    row = @worksheet.num_rows + 1
    (2..8).each do |column|
      @worksheet[row, column] = data[column - 2]
    end
    @worksheet.save
    row
  end
end
