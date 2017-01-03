require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class SourceTest < ActiveSupport::TestCase
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
    s = create_source
    assert_equal 1, s.versions.size
  end

  test "should create version when source is updated" do
    s = create_source
    s.slogan = 'test'
    s.save!
    assert_equal 2, s.versions.size
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
    m = create_valid_media(account: create_valid_account(source: s))
    assert_equal [m], s.medias
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
    assert_not_nil s.avatar_callback(file)
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
    s = create_source
    t = create_tag
    c = create_comment
    s.add_annotation t
    s.add_annotation c
    assert_equal [t], s.tags
  end

  test "should get comments" do
    s = create_source
    t = create_tag
    c = create_comment
    s.add_annotation t
    s.add_annotation c
    assert_equal [c], s.comments
  end

  test "should get db id" do
    s = create_source
    assert_equal s.id, s.dbid
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

end
