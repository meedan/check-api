require_relative '../test_helper'

class TeamSourceTest < ActiveSupport::TestCase
  
  test "should create team source" do
  	assert_difference 'TeamSource.count' do
      create_team_source
    end
  end

   test "should set user" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    s = create_source
    with_current_user_and_team(u, t) do
      ts = create_team_source team: t, source: s
      assert_equal u, ts.user
    end
  end

  test "should have a team and source" do
    assert_no_difference 'TeamSource.count' do
      assert_raise ActiveRecord::RecordInvalid do
        create_team_source team: nil
      end
      assert_raise ActiveRecord::RecordInvalid do
        create_team_source source: nil
      end
    end
  end

  test "should not create duplicated source per team" do
  	t = create_team
    s = create_source
    create_team_source team: t, source: s
    assert_raises ActiveRecord::RecordInvalid do
      create_team_source team: t, source: s
    end
    assert_difference 'TeamSource.count' do
      create_team_source team: create_team, source: s
  	end
  end

  test "should create version when source is created" do
    u = create_user
    create_team_user user: u, role: 'contributor'
    User.current = u
    s = create_source
    assert_operator s.versions.size, :>, 0
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

  test "should have annotations" do
    ts = create_team_source
    c1 = create_comment annotated: ts
    c2 = create_comment annotated: ts
    c3 = create_comment annotated: nil
    assert_equal [c1.id, c2.id].sort, ts.reload.annotations.map(&:id).sort
  end

  test "should not create source under trashed team" do
    t = create_team
    t.archived = true
    t.save!
    s = create_source
    assert_raises ActiveRecord::RecordInvalid do
      create_team_source team: t, source: s
    end
  end

  test "should have description" do
    t = create_team
    s = create_source name: 'foo', slogan: 'bar'
    ts = create_team_source team: t, source: s
    assert_equal 'bar', ts.description
    s.accounts << create_valid_account(data: { description: 'test' })
    assert_equal 'test', ts.description
  end

  test "should get image" do
    url = 'http://checkdesk.org/users/1/photo.png'
    u = create_user profile_image: url
    assert_equal url, u.source.image
  end

  test "should get db id" do
    ts = create_team_source
    assert_equal ts.id, ts.dbid
  end

  test "should get medias" do
    t = create_team
    s = create_source
    p = create_project team: t
    m = create_valid_media(account: create_valid_account(source: s))
    pm = create_project_media project: p, media: m
    ts = create_team_source team: t, source: s
    assert_equal [pm], ts.medias
    # get media for claim attributions
    pm2 = create_project_media project: p, quote: 'Claim', quote_attributions: {name: 'source name'}.to_json
    cs = ClaimSource.where(media_id: pm2.media_id).last
    ts2 = create_team_source team: t, source: cs.source
    assert_equal [pm2], ts2.medias
  end

  test "should get collaborators" do
    u1 = create_user
    u2 = create_user
    u3 = create_user
    s1 = create_team_source
    s2 = create_team_source
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

  test "should get tags" do
    t = create_team
    t2 = create_team
    s = create_source
    ts = create_team_source team: t, source: s
    ts2 = create_team_source team: t2, source: s
    tag = create_tag annotated: ts
    tag2 = create_tag annotated: ts2
    assert_equal [tag, tag2].sort, ts.get_annotations('tag').sort
    Team.stubs(:current).returns(t)
    assert_equal [tag], ts.get_annotations('tag')
    Team.stubs(:current).returns(t2)
    assert_equal [tag2], ts.get_annotations('tag')
    Team.unstub(:current)
  end

  test "should get log" do
    s = create_source
    u = create_user
    t = create_team
    t2 = create_team

    create_team_user user: u, team: t, role: 'owner'

    ts = create_team_source team: t, source: s, user: u

    with_current_user_and_team(u, t) do
      c = create_comment annotated: ts
      tg = create_tag annotated: ts
      f = create_flag annotated: ts
      # ts.identity={name: 'update name'}.to_json
      assert_equal ["create_comment", "create_tag", "create_flag"].sort, ts.get_versions_log.map(&:event_type).sort
      assert_equal 3, ts.get_versions_log_count
      c.destroy!
      assert_equal 3, ts.get_versions_log_count
      tg.destroy!
      assert_equal 3, ts.get_versions_log_count
      f.destroy!
      assert_equal 3, ts.get_versions_log_count
    end
  end

  test "should notify Pusher when source is updated" do
    ts = create_team_source
    ts = TeamSource.find(ts.id)
    assert !ts.sent_to_pusher
    ts.updated_at = Time.now
    ts.save!
    assert ts.sent_to_pusher
  end
    test "should create metadata annotation when source is created" do
    assert_no_difference 'Dynamic.count' do
      create_team_source
    end
    create_annotation_type_and_fields('Metadata', { 'Value' => ['JSON', false] })
    assert_difference 'Dynamic.count' do
      create_team_source
    end
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
    ts = create_team_source source: s
    s.accounts << a
    t1 = a.updated_at
    sleep 2
    ts.refresh_accounts = 1
    ts.save!
    t2 = a.reload.updated_at
    WebMock.allow_net_connect!
    assert t2 > t1
  end

  test "should refresh source with account data" do
    data = { author_name: 'Source author', author_picture: 'picture.png', description: 'Source slogan' }.with_indifferent_access
    Account.any_instance.stubs(:data).returns(data)
    Account.any_instance.stubs(:refresh_pender_data)

    s = create_source name: 'Untitled', slogan: ''
    ts = create_team_source source: s
    a = create_valid_account(source: s)

    ts.refresh_accounts = 1
    ts.reload
    assert_equal 'Source author', ts.name
    assert_equal 'picture.png', ts.avatar
    assert_equal 'Source slogan', ts.slogan
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end

  test "should not refresh source if account data is nil" do
    Account.any_instance.stubs(:data).returns(nil)
    Account.any_instance.stubs(:refresh_pender_data)
    s = create_source name: 'Untitled', slogan: 'Source slogan'
    ts = create_team_source source: s
    a = create_valid_account(source: s)

    ts.refresh_accounts = 1
    ts.reload
    assert_equal 'Untitled', ts.name
    assert_equal 'Source slogan', ts.slogan
    Account.any_instance.unstub(:data)
    Account.any_instance.unstub(:refresh_pender_data)
  end

  test "should set/get source identity" do
    # TODO: Sawy
  end

end
