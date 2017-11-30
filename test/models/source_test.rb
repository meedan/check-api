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

  test "should be unique" do
    t = create_team
    name = 'testing'
    s = create_source team: t, name: name
    assert_no_difference 'Source.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_source name: name
      end
      assert_raises ActiveRecord::RecordInvalid do
        create_source name: name.upcase
      end
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

  test "should set user and team source" do
    u = create_user
    t = create_team
    tu = create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    with_current_user_and_team(u, t) do
      assert_difference 'TeamSource.count' do
        s = create_source project_id: p.id
        assert_equal u, s.user
      end
    end
  end

  test "should get user from callback" do
    u = create_user email: 'test@test.com'
    s = create_source
    assert_equal u.id, s.user_id_callback('test@test.com')
  end

  test "should get avatar from callback" do
    s = create_source
    assert_nil s.avatar_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil s.avatar_callback(file)
    file = 'http://ca.ios.ba/files/others/rails.png'
    assert_nil s.avatar_callback(file)
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

  # test "should not edit same instance concurrently" do
  #   s = create_source
  #   assert_equal 0, s.lock_version
  #   assert_nothing_raised do
  #     s.name = 'Changed'
  #     s.save!
  #   end
  #   assert_equal 1, s.reload.lock_version
  #   assert_raises ActiveRecord::StaleObjectError do
  #     s.lock_version = 0
  #     s.name = 'Changed again'
  #     s.save!
  #   end
  #   assert_equal 1, s.reload.lock_version
  #   assert_nothing_raised do
  #     s.lock_version = 0
  #     s.updated_at = Time.now + 1
  #     s.save!
  #   end
  # end
end
