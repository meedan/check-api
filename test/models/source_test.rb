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
      assert_equal 2, s.versions.size
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
    assert_equal [p1, p2], s.projects
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
    assert_equal [c1.id, c2.id].sort, s.reload.annotations.map(&:id).sort
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
    s = create_source
    u = create_user
    t = create_team
    p = create_project team: t
    p2 = create_project team: t
    create_team_user user: u, team: t, role: 'owner'

    with_current_user_and_team(u, t) do
      ps = create_project_source project: p, source: s, user: u
      ps2 = create_project_source project: p2, source: s, user: u
      c = create_comment annotated: ps
      tg = create_tag annotated: ps
      f = create_flag annotated: ps
      s.name = 'update name'; s.skip_check_ability = true;s.save!;
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
    s = create_source name: 'Untitled'
    s.update_from_pender_data({ 'author_name' => 'Test' })
    assert_equal 'Test', s.name
  end

  test "should not update from Pender data when author_name is blank" do
    s = create_source name: 'Untitled'
    s.update_from_pender_data({ 'author_name' => '' })
    assert_equal 'Untitled', s.name
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

  test "should not create source under trashed team" do
    t = create_team
    t.archived = true
    t.save!

    assert_raises ActiveRecord::RecordInvalid do
      create_source team: t
    end
  end

  test "should refresh source with account data" do
    data = { author_name: 'Source author', author_picture: 'picture.png', description: 'Source slogan' }.with_indifferent_access
    Account.any_instance.stubs(:data).returns(data)
    Account.any_instance.stubs(:refresh_pender_data)

    s = create_source name: 'Untitled', slogan: ''
    a = create_valid_account(source: s)

    s.refresh_accounts = 1
    s.reload
    assert_equal 'Source author', s.name
    assert_equal 'picture.png', s.avatar
    assert_equal 'Source slogan', s.slogan
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end

  test "should not refresh source if account data is nil" do
    Account.any_instance.stubs(:data).returns(nil)
    Account.any_instance.stubs(:refresh_pender_data)
    s = create_source name: 'Untitled', slogan: 'Source slogan'
    a = create_valid_account(source: s)

    s.refresh_accounts = 1
    s.reload
    assert_equal 'Untitled', s.name
    assert_equal 'Source slogan', s.slogan
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end
end
