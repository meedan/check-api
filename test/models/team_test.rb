require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class TeamTest < ActiveSupport::TestCase
  test "should create team" do
    assert_difference 'Team.count' do
      create_team
    end
  end

  test "should not save team without name" do
    t = Team.new
    assert_not t.save

  end
  test "should not save team with invalid subdomains" do
    t = create_team
    t.subdomain = ""
    assert_not t.save
    t.subdomain = "www"
    assert_not t.save
    t.subdomain = "".rjust(64, "a")
    assert_not t.save
    t.subdomain = " some spaces "
    assert_not t.save
    t.subdomain = "correct-الصهث-unicode"
    assert t.save
    t1 = create_team
    t1.subdomain = "correct-الصهث-unicode"
    assert_not t1.save
  end

  test "should create version when team is created" do
    t = create_team
    assert_equal 1, t.versions.size
  end

  test "should create version when team is updated" do
    t = create_team
    t.logo = random_string
    t.save!
    assert_equal 2, t.versions.size
  end

  test "should have users" do
    t = create_team
    u1 = create_user
    u2 = create_user
    assert_equal [], t.users
    t.users << u1
    t.users << u2
    assert_equal [u1, u2], t.users
  end

  test "should have team users" do
    t = create_team
    u1 = create_user
    u2 = create_user
    tu1 = create_team_user user: u1
    tu2 = create_team_user user: u2
    assert_equal [], t.team_users
    t.team_users << tu1
    t.team_users << tu2
    assert_equal [tu1, tu2], t.team_users
    assert_equal [u1, u2], t.users
  end

  test "should get logo from callback" do
    t = create_team
    assert_nil t.logo_callback('')
    file = 'http://checkdesk.org/users/1/photo.png'
    assert_nil t.logo_callback(file)
    file = 'http://dummyimage.com/100x100/000/fff.png'
    assert_not_nil t.logo_callback(file)
  end

  test "should add user to team on team creation" do
    u = create_user
    assert_difference 'TeamUser.count' do
      create_team current_user: u
    end
  end

  test "should not add user to team on team creation" do
    assert_no_difference 'TeamUser.count' do
      create_team current_user: nil
    end
  end

  test "should create project in team on team creation" do
    assert_difference 'Project.count' do
      create_team
    end
  end

  test "should not upload a logo that is not an image" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big logo" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small logo" do
    assert_no_difference 'Team.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_team logo: 'ruby-small.png'
      end
    end
  end

  test "should have a default uploaded image" do
    t = create_team logo: nil
    assert_match /team\.png$/, t.logo.url
  end

  test "should have avatar" do
    t = create_team logo: nil
    assert_match /^http/, t.avatar
  end

  test "should have members count" do
    t = create_team
    t.users << create_user
    t.users << create_user
    assert_equal 2, t.members_count
  end
end
