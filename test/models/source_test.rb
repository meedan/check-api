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

  test "should get db id" do
    s = create_source
    assert_equal s.id, s.dbid
  end

  test "should get permissions" do
    u = create_user
    t = create_team current_user: u
    s = create_source
    s.context_team = t
    s.current_user = u
    perm_keys = ["read Source", "update Source", "destroy Source", "create Account", "create ProjectSource", "create Project"].sort
    # load permissions as owner
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    s.current_user = u.reload
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
    # load as editor
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    s.current_user = u.reload
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
    # load as journalist
    tu = u.team_users.last; tu.role = 'journalist'; tu.save!
    s.current_user = u.reload
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
    # load as contributor
    tu = u.team_users.last; tu.role = 'contributor'; tu.save!
    s.current_user = u.reload
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
    # load as authenticated
    tu = u.team_users.last; tu.role = 'editor'; tu.save!
    tu.delete
    s.current_user = u.reload
    assert_equal perm_keys, JSON.parse(s.permissions).keys.sort
  end

end
