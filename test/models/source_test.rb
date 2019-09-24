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
      assert_raises ActiveRecord::RecordInvalid do
        create_source team: t, name: name.upcase
      end
    end
  end

  test "should create version when source is created" do
    u = create_user
    create_team_user user: u, role: 'contributor'
    User.current = u
    s = create_source
    assert_equal 1, s.versions.size
    User.current = nil
  end

  test "should create version when source is updated" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    with_current_user_and_team(u, t) do
      s = create_source
      s.slogan = 'test'
      s.save!
      assert_equal 3, s.versions.size
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

  test "should have project sources" do
    ps1 = create_project_source
    ps2 = create_project_source
    s = create_source
    assert_equal [], s.project_sources
    s.project_sources << ps1
    s.project_sources << ps2
    assert_equal [ps1, ps2], s.project_sources
  end

  test "should have projects" do
    p1 = create_project
    p2 = create_project
    ps1 = create_project_source project: p1
    ps2 = create_project_source project: p2
    s = create_source
    assert_equal [], s.project_sources
    s.project_sources << ps1
    s.project_sources << ps2
    assert_equal [p1, p2].to_a.sort, s.projects.to_a.sort
  end

  test "should have user" do
    u = create_user
    s = create_source user: u
    assert_equal u, s.user
  end

  test "should set user and team" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      s = create_source project_id: p.id
      assert_equal u, s.user
      assert_equal t, s.team
    end
  end

  test "should have annotations" do
    s = create_source
    c1 = create_comment
    c2 = create_comment
    c3 = create_comment
    s.add_annotation(c1)
    s.add_annotation(c2)
    assert_equal [c1.id, c2.id].sort, s.reload.annotations.where(annotation_type: 'comment').map(&:id).sort
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
    s = create_source
    p = create_project
    m = create_valid_media(account: create_valid_account(source: s))
    pm = create_project_media project: p, media: m
    assert_equal [pm], s.medias
    # get media for claim attributions
    pm2 = create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'source name'}.to_json
    cs = ClaimSource.where(media_id: pm2.media_id).last
    assert_not_nil cs.source
    assert_equal [pm2], cs.source.medias
  end

  test "should get collaborators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_source
    s2 = create_source
    c1 = create_comment annotator: u1, annotated: s1
    c2 = create_comment annotator: u1, annotated: s1
    c3 = create_comment annotator: u1, annotated: s1
    c4 = create_comment annotator: u2, annotated: s1
    c5 = create_comment annotator: u2, annotated: s1
    c6 = create_comment annotator: u3, annotated: s2
    c7 = create_comment annotator: u3, annotated: s2
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

  test "should get tags" do
    t = create_team
    t2 = create_team
    p = create_project team: t
    p2 = create_project team: t2
    s = create_source
    ps = create_project_source project: p, source: s
    ps2 = create_project_source project: p2, source: s
    tag = create_tag annotated: ps
    tag2 = create_tag annotated: ps2
    assert_equal [tag, tag2].sort, s.get_annotations('tag').sort
    Team.stubs(:current).returns(t)
    assert_equal [tag], s.get_annotations('tag')
    Team.stubs(:current).returns(t2)
    assert_equal [tag2], s.get_annotations('tag')
    Team.unstub(:current)
  end

  test "should get db id" do
    s = create_source
    assert_equal s.id, s.dbid
  end

  test "journalist should edit any source" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'journalist'
    with_current_user_and_team(u, t) do
      s = create_source user: create_user
      s.name = 'update source'
      assert_nothing_raised RuntimeError do
        s.save!
      end
    end
  end

  test "should get permissions" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    s = create_source
    perm_keys = ["read Source", "update Source", "destroy Source", "create Account", "create ProjectSource", "create Project"].sort

    # load permissions as owner
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }

    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    with_current_user_and_team(u, t) { assert_equal perm_keys, JSON.parse(s.permissions).keys.sort }
  end

  test "should get team" do
    t = create_team
    p = create_project team: t
    ps = create_project_source project: p
    s = create_source
    s.project_sources << ps
    assert_equal [t.id], s.get_team
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
        create_source file: 'not-an-image.txt'
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

  test "should get log" do
    u = create_user
    t = create_team
    s = create_source team: t
    p = create_project team: t
    p2 = create_project team: t
    create_team_user user: u, team: t, role: 'owner'

    with_current_user_and_team(u, t) do
      ps = create_project_source project: p, source: s, user: u
      ps2 = create_project_source project: p2, source: s, user: u
      c = create_comment annotated: ps
      tg = create_tag annotated: ps
      f = create_flag annotated: ps
      s.name = 'update name'; s.skip_check_ability = true; s.save!
      c2 = create_comment annotated: ps2
      f2 = create_flag annotated: ps2
      assert_equal ["create_comment", "create_tag", "create_flag", "update_source", "create_comment", "create_flag"].sort, s.get_versions_log.map(&:event_type).sort
      assert_equal 6, s.get_versions_log_count
      c.destroy!
      assert_equal 6, s.get_versions_log_count
      tg.destroy!
      assert_equal 6, s.get_versions_log_count
      f.destroy!
      assert_equal 6, s.get_versions_log_count
      c2.destroy!
      assert_equal 6, s.get_versions_log_count
      f2.destroy!
      assert_equal 6, s.get_versions_log_count
    end
  end

  test "should notify Pusher when source is updated" do
    s = create_source
    s = Source.find(s.id)
    assert !s.sent_to_pusher
    s.updated_at = Time.now
    s.save!
    assert s.sent_to_pusher
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias?url=' + url
    pender_refresh_url = CONFIG['pender_url_private'] + '/api/medias?refresh=1&url=' + url + '/'
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
    t.archived = true
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
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
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

  test "should get medias count" do
    s = create_source
    p = create_project
    m = create_valid_media(account: create_valid_account(source: s))
    pm = create_project_media project: p, media: m
    assert_equal [pm], s.medias
    # get media for claim attributions
    pm2 = create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'source name'}.to_json
    cs = ClaimSource.where(media_id: pm2.media_id).last
    assert_not_nil cs.source
    assert_equal 1, cs.source.medias_count
  end

  test "should get accounts count" do
    s = create_source
    assert_equal s.accounts.count, s.accounts_count
  end
end
