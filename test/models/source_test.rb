require_relative '../test_helper'

class SourceTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end

  test "should create source" do
    u = create_user
    assert_difference 'Source.count' do
      create_source user: u
    end
  end

  test "should not save source without name" do
    source = Source.new
    assert_not  source.save
  end

  test "should be unique per team" do
    t = create_team
    name = 'testing'
    s = create_source team: t, name: name
    assert_nothing_raised do
      create_source team: t
      create_source team: create_team, name: name
      create_source team: nil
    end
    assert_no_difference 'Source.count' do
      assert_raises RuntimeError do
        create_source team: t, name: name.upcase
      end
    end
  end

  test "should have accounts" do
    a1 = create_valid_account
    a2 = create_valid_account
    s = create_source
    assert_equal [], s.accounts
    s.accounts << a1
    s.accounts << a2
    assert_equal [a1, a2], s.accounts
  end

  test "should have user" do
    u = create_user
    s = create_source user: u
    assert_equal u, s.user
  end

  test "should set user and team" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      s = create_source team: t
      assert_equal u, s.user
      assert_equal t, s.team
    end
  end

  test "should have annotations" do
    s = create_source
    t1 = create_tag
    t2 = create_tag
    t3 = create_tag
    s.add_annotation(t1)
    s.add_annotation(t2)
    assert_equal [t1.id, t2.id].sort, s.reload.annotations.where(annotation_type: 'tag').map(&:id).sort
  end

  test "should get user from callback" do
    u = create_user email: 'test@test.com'
    s = create_source
    assert_equal u.id, s.user_id_callback('test@test.com')
  end

  test "should get image" do
    url = 'http://checkdesk.org/users/1/photo.png'
    u = create_user profile_image: url
    assert_equal url, u.source.image
  end

  test "should get medias" do
    t = create_team
    s = create_source name: 'testing', team: t
    pm = create_project_media team: t, source: s, skip_autocreate_source: false
    assert_equal [pm], s.medias
    assert_equal 1, s.medias_count
  end

  test "should get collaborators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_source
    s2 = create_source
    d1 = create_dynamic_annotation annotator: u1, annotated: s1
    d2 = create_dynamic_annotation annotator: u1, annotated: s1
    d3 = create_dynamic_annotation annotator: u1, annotated: s1
    d4 = create_dynamic_annotation annotator: u2, annotated: s1
    d5 = create_dynamic_annotation annotator: u2, annotated: s1
    d6 = create_dynamic_annotation annotator: u3, annotated: s2
    d7 = create_dynamic_annotation annotator: u3, annotated: s2
    assert_equal [u1, u2].sort, s1.collaborators.sort
    assert_equal [u3].sort, s2.collaborators.sort
  end

  test "should get avatar from callback" do
    s = create_source
    assert_nil s.avatar_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil s.avatar_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_nil s.avatar_callback(file)
  end

  test "should have description" do
    s = create_source name: 'foo', slogan: 'bar'
    assert_equal 'bar', s.description
    s = create_source name: 'foo', slogan: 'foo'
    assert_equal '', s.description
    s.accounts << create_valid_account(data: { description: 'test' })
    assert_equal 'test', s.description
  end

  test "should get annotations" do
    t = create_team
    t2 = create_team
    s = create_source team: t
    tag = create_tag annotated: s
    tag2 = create_tag annotated: s
    assert_equal [tag, tag2].sort, s.get_annotations('tag').sort
  end

  test "should get db id" do
    s = create_source
    assert_equal s.id, s.dbid
  end

  test "editor should edit any source" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'editor'
    with_current_user_and_team(u, t) do
      s = create_source user: create_user
      s.name = 'update source'
      assert_nothing_raised do
        s.save!
      end
    end
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'admin'
    s = create_source
    perm_keys = ["read Source", "update Source", "destroy Source", "create Account", "create Task", "create Dynamic"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as collaborator
    tu = u.team_users.last; tu.role = 'collaborator'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }
  end

  test "should protect attributes from mass assignment" do
    raw_params = { name: "My source", user: create_user }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Source.create(params)
    end
  end

  test "should have image" do
    c = nil
    assert_difference 'Source.count' do
      c = create_source file: 'rails.png'
    end
    assert_not_nil c.file
  end

  test "should not upload a file that is not an image" do
    assert_no_difference 'Source.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source file: 'not-an-image.csv'
      end
    end
  end

  test "should not upload a big image" do
    assert_no_difference 'Source.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source file: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small image" do
    assert_no_difference 'Source.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source file: 'ruby-small.png'
      end
    end
  end

  test "should update from Pender data" do
    s = create_source name: 'Untitled-123'
    s.update_from_pender_data({ 'author_name' => 'Test' })
    assert_equal 'Test', s.name
  end

  test "should not update from Pender data when author_name is blank" do
    gname = 'Untitled-123'
    s = create_source name: gname
    s.update_from_pender_data({ 'author_name' => '' })
    assert_equal gname, s.name
  end

  test "should refresh source and accounts" do
    WebMock.disable_net_connect!
    url = "http://twitter.com/example#{Time.now.to_i}"
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias?url=' + url
    pender_refresh_url = CheckConfig.get('pender_url_private') + '/api/medias?refresh=1&url=' + url + '/'
    ret = { body: '{"type":"media","data":{"url":"' + url + '/","type":"profile"}}' }
    WebMock.stub_request(:get, pender_url).to_return(ret)
    WebMock.stub_request(:get, pender_refresh_url).to_return(ret)
    a = create_account url: url
    s = create_source
    s.accounts << a
    t1 = a.updated_at
    sleep 2
    s.refresh_accounts = 1
    s.save!
    t2 = a.reload.updated_at
    WebMock.allow_net_connect!
    assert t2 > t1
  end

  test "should refresh source and user account with user omniauth_info" do
    info = {"name"=>"Daniela Feitosa", name: 'Daniela Feitosa'}
    url = "https://meedan.slack.com/team/daniela"
    u = create_omniauth_user provider: 'twitter', info: info, url: url
    a = u.get_social_accounts_for_login({provider: 'twitter'}).first
    assert_equal 'https://meedan.slack.com/team/daniela', a.url
    assert_equal 'Daniela Feitosa', a.data['author_name']

    a.omniauth_info['info']['name'] = 'Daniela'
    a.omniauth_info['url'] = 'http://example.com'
    a.save

    s = u.source
    s.name = ''; s.save
    t1 = a.updated_at
    sleep 2
    s.refresh_accounts = 1
    s.save!
    t2 = a.reload.updated_at
    assert t2 > t1
    assert_equal 'http://example.com', a.url
    assert_equal 'Daniela', a.data['author_name']
    assert_equal 'Daniela', s.name
  end

  test "should not create source under trashed team" do
    t = create_team
    t.archived = 1
    t.save!

    assert_raises ActiveRecord::RecordInvalid do
      create_source team: t
    end
  end

  test "should create source with pender data and add avatar on save" do
    s = Source.new name: '@CBSNews'
    assert_nothing_raised do
      s.set_avatar('picture.png')
      s.save!
      assert_equal 'picture.png', Source.find(s.id).avatar
    end
  end

  test "should update source directly on db for existing source" do
    s = create_source name: '@CBSNews'
    assert_nothing_raised do
      s.set_avatar('picture.png')
      assert_equal 'picture.png', Source.find(s.id).avatar
    end
  end

  test "should refresh source with account data" do
    s = create_source name: 'Untitled-123', slogan: '', avatar: 'old.png'
    a = create_valid_account(source: s)
    assert_equal 'old.png', s.avatar

    data = { author_name: 'Source author', author_picture: 'picture.png', description: 'Source slogan' }.with_indifferent_access
    Account.any_instance.stubs(:data).returns(data)
    Account.any_instance.stubs(:refresh_pender_data)

    s.refresh_accounts = 1
    s.reload
    assert_equal 'Source author', s.name
    assert_empty s.slogan
    assert_equal 'picture.png', s.image
    assert_equal 'Source slogan', s.description
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end

  test "should refresh source with account data except the image when is uploaded file" do
    data = { author_name: 'Source author', picture: 'picture.png', description: 'Source slogan' }.with_indifferent_access
    Account.any_instance.stubs(:data).returns(data)
    Account.any_instance.stubs(:refresh_pender_data)

    s = create_source file: 'rails.png'
    assert_match /rails.png/, s.image
    a = create_valid_account(source: s)

    s.refresh_accounts = 1
    s.reload
    assert_equal 'picture.png', s.accounts.first.data['picture'].to_s
    assert_match /rails.png/, s.image
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end


  test "should get overridden values" do
    keys = %W(name description image)
    # source with no account
    s = create_source
    overridden = s.overridden
    keys.each {|k| assert overridden[k]}
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias'
    author_url = 'http://facebook.com/123456'
    data = { url: author_url, picture: 'http://fb/p.png', author_name: 'username', description: 'Bar', type: 'profile' }
    response = '{"type":"media","data":' + data.to_json + '}'
    WebMock.stub_request(:get, pender_url).with({ query: { url: author_url } }).to_return(body: response)
    # source with one account
    a = create_account url: author_url, source: nil
    s = a.sources.last
    overridden = s.overridden
    keys.each {|k| assert_equal overridden[k], a.id}
    # source with multiple account
    create_account_source source: s
    overridden = s.reload.overridden
    keys.each {|k| assert_equal overridden[k], a.id}
    s.name = 'test'; s.save!
    assert s.overridden['name']
    assert_equal s.overridden['description'], a.id
    s.slogan = 'update bio'; s.save;
    assert s.overridden['name']
    assert s.overridden['description']
    s.slogan = 'update bio'; s.save;
    assert s.overridden['name']
    assert s.overridden['description']
    s.file = 'rails.png'; s.save!
    overridden = s.overridden
    keys.each {|k| assert overridden[k]}
    # re-test after clear overridden cache.
    Rails.cache.delete("source_overridden_cache_#{s.id}")
    overridden = s.overridden
    keys.each {|k| assert overridden[k]}
  end

  test "should not refresh source if account data is nil" do
    Account.any_instance.stubs(:data).returns(nil)
    Account.any_instance.stubs(:refresh_pender_data)
    s = create_source name: 'Untitled-123', slogan: 'Source slogan'
    a = create_valid_account(source: s)

    s.refresh_accounts = 1
    s.reload
    assert_equal 'Untitled-123', s.name
    assert_equal 'Source slogan', s.slogan
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end

  test "should not edit same instance concurrently" do
    s = create_source
    assert_equal 0, s.lock_version
    assert_nothing_raised do
      s.name = 'Changed'
      s.save!
    end
    assert_equal 1, s.reload.lock_version
    assert_raises ActiveRecord::StaleObjectError do
      s.lock_version = 0
      s.name = 'Changed again'
      s.save!
    end
    assert_equal 1, s.reload.lock_version
    assert_nothing_raised do
      s.lock_version = 0
      s.updated_at = Time.now + 1
      s.save!
    end
  end

  test "should create metadata annotation when source is created" do
    assert_difference "Dynamic.where(annotation_type: 'metadata').count" do
      create_source
    end
  end

  test "should get accounts count" do
    s = create_source
    assert_equal s.accounts.count, s.accounts_count
  end

  test "should refresh source using account team pender_key" do
    t = create_team
    a = create_account
    s = create_source team: t
    s.accounts << a

    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: a.url, refresh: '1' }, CheckConfig.get('pender_key'), nil).returns({"type" => "media","data" => {"url" => a.url, "type" => "profile", "title" => "Default token", "author_name" => 'Author with default token'}})
    PenderClient::Request.stubs(:get_medias).with(CheckConfig.get('pender_url_private'), { url: a.url, refresh: '1' }, 'specific_token', nil).returns({"type" => "media","data" => {"url" => a.url, "type" => "profile", "title" => "Author with specific token", "author_name" => 'Author with specific token'}})

    s.refresh_accounts = true
    s.save!

    assert_equal 'Author with default token', Account.find(a.id).metadata['author_name']

    t.set_pender_key = 'specific_token'; t.save!
    s = Source.find(s.id)
    s.refresh_accounts = true
    s.save!
    assert_equal 'Author with specific token', Account.find(a.id).metadata['author_name']
    PenderClient::Request.unstub(:get_medias)
  end

  test "should relate source to project media" do
    setup_elasticsearch
    t = create_team
    pm = create_project_media team: t, disable_es_callbacks: false
    id = get_es_id(pm)
    s = create_source team: t
    sleep 2
    assert_not_equal s.id, pm.source_id
    result = $repository.find(id)
    assert_equal pm.source_id, result['source_id']
    s.add_to_project_media_id = pm.id
    s.disable_es_callbacks = false
    s.save!
    sleep 2
    assert_equal s.project_media, pm
    assert_equal s.id, pm.reload.source_id
    result = $repository.find(id)
    assert_equal pm.reload.source_id, result['source_id']
  end

  test "should create source accounts" do
    WebMock.disable_net_connect!
    url = "http://twitter.com/example#{Time.now.to_i}"
    pender_url = CheckConfig.get('pender_url_private') + '/api/medias?url=' + url
    ret = { body: '{"type":"media","data":{"url":"' + url + '/","type":"profile"}}' }
    WebMock.stub_request(:get, pender_url).to_return(ret)
    s = create_source urls: [url].to_json
    assert_equal 1, s.accounts.count
    WebMock.allow_net_connect!
    # validate primary url exists
    t = create_team
    Team.stubs(:current).returns(t)
    s.update_columns(team_id: t.id)
    assert_raises RuntimeError do
      create_source  urls: [url].to_json, validate_primary_link_exist: true
    end
    assert_difference 'Source.count' do
      create_source  urls: [url].to_json
    end
    Team.unstub(:current)
  end

  test "should assign task to sources" do
    create_task_stuff
    team = create_team
    tt = create_team_task team_id: team.id
    s = create_source team: team
    t = create_task annotated: s, type: 'multiple_choice', options: ['Apple', 'Orange', 'Banana'], label: 'Fruits you like', team_task_id: tt.id
    t.response = { annotation_type: 'task_response_multiple_choice', set_fields: { response_multiple_choice: { selected: ['Apple', 'Orange'], other: nil }.to_json }.to_json }.to_json
    t.save!
    r = t.responses.first
    assert_not_nil r
    t.destroy
    assert_nil Annotation.where(id: r.id).last
  end
end
