require_relative '../test_helper'

class AdminAbilityTest < ActiveSupport::TestCase

  def setup
    super
    @t = create_team
    Team.stubs(:current).returns(@t)
    @u = create_user
    @tu = create_team_user user: u , team: t, role: 'owner'
  end

  def teardown
    super
    Team.unstub(:current)
  end

  attr_reader :u, :t, :tu

  test "owner permissions for project" do
    team_project = create_project team: t
    own_project = create_project team: t, user: u
    other_project = create_project
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, Project)
      assert ability.can?(:index, team_project)
      assert ability.can?(:read, team_project)
      assert ability.can?(:update, team_project)
      assert ability.can?(:destroy, team_project)

      assert ability.can?(:index, own_project)
      assert ability.can?(:read, own_project)
      assert ability.can?(:update, own_project)
      assert ability.can?(:destroy, own_project)

      assert ability.cannot?(:index, other_project)
      assert ability.cannot?(:read, other_project)
      assert ability.cannot?(:update, other_project)
      assert ability.cannot?(:destroy, other_project)
    end
  end

  test "owner permissions for media" do
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, Media)
      assert ability.cannot?(:update, m)
      assert ability.cannot?(:update, own_media)
      assert ability.cannot?(:destroy, m)
      assert ability.cannot?(:destroy, own_media)
      assert ability.cannot?(:update, m2)
      assert ability.cannot?(:destroy, m2)
    end
  end

  test "owner permissions for project media" do
    m = create_valid_media
    p = create_project team: t
    pm = create_project_media project: p, media: m
    own_media = create_valid_media user_id: u.id
    own_pm = create_project_media project: p, media: own_media
    m2 = create_valid_media
    pm2 = create_project_media media: m2
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
      assert ability.cannot?(:update, pm)
      assert ability.cannot?(:update, own_pm)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:destroy, pm2)
    end
  end

  test "owner permissions for team" do
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'owner'
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:read, t)
      assert ability.can?(:update, t)
      assert ability.cannot?(:create, Team)
      assert ability.cannot?(:destroy, t)
      assert ability.cannot?(:update, t2)
      assert ability.cannot?(:destroy, t2)
    end
  end

  test "owner permissions for teamUser" do
    u2 = create_user
    tu2 = create_team_user team: t, role: 'editor'
    tu_other = create_team_user

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, TeamUser)
      assert ability.cannot?(:update, tu2)
      assert ability.cannot?(:destroy, tu2)
      assert ability.cannot?(:update, tu_other)
      assert ability.cannot?(:destroy, tu_other)
    end
  end

  test "owner permissions for contact" do
    c = create_contact team: t
    c1 = create_contact

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, Contact)
      assert ability.cannot?(:read, c)
      assert ability.cannot?(:update, c)
      assert ability.cannot?(:destroy, c)
      assert ability.cannot?(:update, c1)
      assert ability.cannot?(:destroy, c1)
    end
  end

  test "owner permissions for user" do
    u2_test = create_user
    tu2_test = create_team_user user: u2_test , role: 'contributor'
    u_test1 = create_user
    tu_test1 = create_team_user team: t, user: u_test1, role: 'editor'

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, u)
      assert ability.cannot?(:destroy, u)
      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'journalist')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      tu_test1.update_column(:role, 'contributor')

      assert ability.cannot?(:update, u_test1)
      assert ability.cannot?(:destroy, u_test1)

      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "owner cannot see users not member of his teams" do
    u_member = create_user
    tu_member = create_team_user team: t, user: u_member, role: 'contributor', status: 'member'
    u_requested = create_user
    tu_requested = create_team_user team: t, user: u_requested, role: 'contributor', status: 'requested'
    u_invited = create_user
    tu_invited = create_team_user team: t, user: u_invited, role: 'contributor', status: 'invited'
    u_banned = create_user
    tu_banned = create_team_user team: t, user: u_banned, role: 'contributor', status: 'banned'
    u_other_team = create_user
    tu_other_team = create_team_user user: u_other_team, role: 'contributor', status: 'member'


    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, u_member)
      assert ability.cannot?(:update, u_member)
      assert ability.cannot?(:destroy, u_member)

      assert ability.cannot?(:read, u_requested)
      assert ability.cannot?(:update, u_requested)
      assert ability.cannot?(:destroy, u_requested)

      assert ability.cannot?(:read, u_invited)
      assert ability.cannot?(:update, u_invited)
      assert ability.cannot?(:destroy, u_invited)

      assert ability.cannot?(:read, u_banned)
      assert ability.cannot?(:update, u_banned)
      assert ability.cannot?(:destroy, u_banned)

      assert ability.cannot?(:read, u_other_team)
      assert ability.cannot?(:update, u_other_team)
      assert ability.cannot?(:destroy, u_other_team)
    end
  end

  test "owner permissions for comment" do
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, Comment)
      assert ability.cannot?(:update, mc)
      assert ability.can?(:destroy, mc)
    end
  end

  test "owner of other team permissions for comment" do
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc

    other_user = create_user
    create_team_user user: other_user, team: create_team, role: 'owner'

    with_current_user_and_team(other_user) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, Comment)
      assert ability.cannot?(:update, mc)
      assert ability.cannot?(:destroy, mc)
    end
  end

  test "check annotation permissions" do
    # test the create/update/destroy operations
    tu.role = 'journalist'
    tu.save
    p = create_project team: t
    pm = create_project_media project: p
    c = create_comment annotated: pm

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, c)
      assert ability.cannot?(:destroy, c)
    end

    tu.role = 'owner'; tu.save!

    Rails.cache.clear
    c.text = 'for testing';c.save!
    assert_equal c.text, 'for testing'

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, c)
      assert ability.can?(:destroy, c)
    end
  end

  test "owner permissions for status" do
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = create_status status: 'verified', annotated: pm
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, s)
      assert ability.can?(:update, s)
      assert ability.can?(:destroy, s)
    end
  end

  test "owner permissions for embed" do
    p = create_project team: t
    pm = create_project_media project: p
    em = create_metadata annotated: pm
    link = create_valid_media({ type: 'link', team: t })
    em_link = create_metadata annotated: link
    account = create_valid_account team: t
    em_account = create_metadata annotated: account
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, em)
      assert ability.cannot?(:read, em)
      assert ability.can?(:update, em)
      assert ability.can?(:destroy, em)
      assert ability.cannot?(:read, em_link)
      assert ability.cannot?(:update, em_link)
      assert ability.cannot?(:destroy, em_link)
      assert ability.can?(:update, em_account)
      assert ability.cannot?(:read, em_account)
      assert ability.can?(:destroy, em_account)
    end
  end

  test "owner permissions for tag" do
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', annotated: pm
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
    end
  end

  test "owner of other team permissions for tag" do
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', annotated: pm

    other_user = create_user
    create_team_user user: other_user, team: create_team, role: 'owner'

    with_current_user_and_team(other_user) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.cannot?(:destroy, tg)
    end
  end

  test "only admin users can manage all" do
    u = create_user
    u.is_admin = true
    u.save
    ability = AdminAbility.new(u)
    assert ability.can?(:manage, :all)
  end

  test "admins can do anything" do
    u = create_user
    u.is_admin = true
    u.save
    t = create_team
    tu = create_team_user user: u , team: t
    p = create_project team: t
    own_project = create_project team: t, user: u
    p2 = create_project

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, Project)
      assert ability.can?(:update, p)
      assert ability.can?(:update, own_project)
      assert ability.can?(:destroy, p)
      assert ability.can?(:destroy, own_project)
      assert ability.can?(:update, p2)
      assert ability.can?(:destroy, p2)
    end
  end

  test "should not read source without user" do
    s = create_source user: nil
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, s)
    end
  end

  test "should not read own source" do
    s = create_source user: u
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, s)
    end
  end

  test "should not read source from other team user" do
    other_user = create_user
    tu_other = create_team_user user: other_user , team: create_team, role: 'owner'
    s = create_source user: other_user
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, s)
      assert ability.cannot?(:update, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "should not read source from team user" do
    same_team_user = create_user
    tu_other = create_team_user user: same_team_user, team: t, role: 'contributor'
    s = create_source user: same_team_user
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, s)
      assert ability.cannot?(:update, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "should only destroy annotation from user teams" do
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a_from_team = create_annotation annotated: pm1
    a2_from_team = create_annotation annotated: pm2
    a_from_other_team = create_annotation annotated: create_project_media
    with_current_user_and_team(u) do
      a = AdminAbility.new
      assert a.can?(:destroy, a_from_team)
      assert a.can?(:destroy, a2_from_team)
      assert a.cannot?(:destroy, a_from_other_team)
    end
  end

  test "should not destroy annotation versions" do
    p = create_project team: t
    pm = create_project_media project: p
    begin create_verification_status_stuff rescue nil end
    with_current_user_and_team(u) do
      s = create_status annotated: pm, status: 'verified'
      em = create_metadata annotated: pm
      s_v = s.versions.last
      em_v = em.versions.last
      ability = AdminAbility.new
      # Status versions
      assert ability.can?(:create, s_v)
      assert ability.cannot?(:read, s_v)
      assert ability.cannot?(:update, s_v)
      assert ability.cannot?(:destroy, s_v)
      # Embed versions
      assert ability.can?(:create, em_v)
      assert ability.cannot?(:read, em_v)
      assert ability.cannot?(:update, em_v)
      assert ability.cannot?(:destroy, em_v)
    end
  end

  test "should access rails_admin if user is team owner" do
    p = create_project team: t

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:access, :rails_admin)
    end
  end

  test "should not access rails_admin if user not team owner or admin" do
    tu.role = 'contributor'
    tu.save
    p = create_project team: t

    %w(contributor journalist editor).each do |role|
      tu.role = role; tu.save!
      with_current_user_and_team(u) do
        ability = AdminAbility.new
        assert !ability.can?(:access, :rails_admin)
      end
    end
  end

  test "owner permissions for task" do
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    tk = create_task annotator: u, annotated: pm
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tk)
    end
  end

  test "owner permissions for dynamic annotation" do
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    oda = create_dynamic_annotation
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u, t) do
      ability = AdminAbility.new
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
      assert ability.can?(:update, da)
      assert ability.can?(:destroy, da)
      assert ability.cannot?(:update, oda)
      assert ability.cannot?(:destroy, oda)
    end
  end

  test "owner permissions for export project data" do
    project = create_project team: @t
    project2 = create_project
    with_current_user_and_team(@u, @t) do
      ability = Ability.new
      assert ability.can?(:export_project, project)
      assert ability.cannot?(:export_project, project2)
    end
  end

  test "owner permissions to task" do
    task = create_task annotator: u, team: t
    create_annotation_type annotation_type: 'response'
    task.response = { annotation_type: 'response', set_fields: {} }.to_json
    task.save!
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, Task)
      assert ability.cannot?(:update, task)
      assert ability.can?(:destroy, task)
    end
  end

  test "owner of other team permissions for task" do
    task = create_task annotator: u, team: t
    create_annotation_type annotation_type: 'response'
    task.response = { annotation_type: 'response', set_fields: {} }.to_json
    task.save!

    other_user = create_user
    create_team_user user: other_user, team: create_team, role: 'owner'

    with_current_user_and_team(other_user) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, Task)
      assert ability.cannot?(:update, task)
      assert ability.cannot?(:destroy, task)
    end
  end

  test "owner permissions to dynamic annotation" do
    p = create_project team: t
    pm = create_project_media project: p
    task = create_task annotator: u, annotated: pm
    dynamic_field = create_field annotation_id: task.id
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, DynamicAnnotation::Field)
      assert ability.cannot?(:update, dynamic_field)
      assert ability.can?(:destroy, dynamic_field)
    end
  end

  test "owner of other team permissions for dynamic annotation" do
    p = create_project team: t
    pm = create_project_media project: p
    task = create_task annotator: u, annotated: pm
    dynamic_field = create_field annotation_id: task.id

    other_user = create_user
    create_team_user user: other_user, team: create_team, role: 'owner'

    with_current_user_and_team(other_user) do
      ability = AdminAbility.new
      assert ability.cannot?(:update, DynamicAnnotation::Field)
      assert ability.cannot?(:update, dynamic_field)
      assert ability.cannot?(:destroy, dynamic_field)
    end
  end

  test "owner permissions to dynamic" do
    p = create_project team: t
    pm = create_project_media project: p
    s = create_status annotated: pm, status: 'verified'
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:destroy, s)
      assert ability.can?(:update, s)
    end
  end

  test "owner permissions for team bot" do
    tb1 = create_team_bot team_author_id: t.id
    tb2 = create_team_bot
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, tb1)
      assert ability.can?(:update, tb1)
      assert ability.can?(:destroy, tb1)
      assert ability.can?(:index, tb1)
      assert ability.can?(:read, tb1)
      assert ability.can?(:destroy, tb1.source)
      assert ability.can?(:destroy, tb1.api_key)
    end
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tb2)
      assert ability.cannot?(:update, tb2)
      assert ability.cannot?(:destroy, tb2)
      assert ability.cannot?(:index, tb2)
      assert ability.cannot?(:read, tb2)
      assert ability.cannot?(:destroy, tb2.source)
      assert ability.cannot?(:destroy, tb2.api_key)
    end
  end

  test "owner permissions for team bot installation" do
    tb1 = create_team_bot_installation team_id: t.id
    tb2 = create_team_bot_installation
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, tb1)
      assert ability.can?(:update, tb1)
      assert ability.can?(:destroy, tb1)
      assert ability.can?(:index, tb1)
      assert ability.can?(:read, tb1)
    end
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tb2)
      assert ability.cannot?(:update, tb2)
      assert ability.cannot?(:destroy, tb2)
      assert ability.cannot?(:index, tb2)
      assert ability.cannot?(:read, tb2)
    end
  end

  test "permissions for approved bots" do
    tb1 = create_team_bot set_approved: true
    tb2 = create_team_bot set_approved: false
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tb1)
      assert ability.cannot?(:update, tb1)
      assert ability.cannot?(:destroy, tb1)
      assert ability.cannot?(:index, tb1)
      assert ability.cannot?(:read, tb1)
      assert ability.can?(:install, tb1)
    end
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:create, tb2)
      assert ability.cannot?(:update, tb2)
      assert ability.cannot?(:destroy, tb2)
      assert ability.cannot?(:index, tb2)
      assert ability.cannot?(:read, tb2)
      assert ability.cannot?(:install, tb2)
    end
  end
end
