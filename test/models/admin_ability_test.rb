require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AdminAbilityTest < ActiveSupport::TestCase

  def setup
    WebMock.stub_request(:post, /#{Regexp.escape(CONFIG['bridge_reader_url_private'])}.*/)
    @u = create_user
    @t = create_team
    @tu = create_team_user user: u , team: t, role: 'owner'
  end
  attr_reader :u, :t, :tu

  test "owner permissions for project" do
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
      assert ability.cannot?(:update, p2)
      assert ability.cannot?(:destroy, p2)
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
      assert ability.can?(:create, Media)
      assert ability.can?(:update, m)
      assert ability.can?(:update, own_media)
      assert ability.can?(:destroy, m)
      assert ability.can?(:destroy, own_media)
      assert ability.can?(:update, pm)
      assert ability.can?(:update, own_pm)
      assert ability.can?(:destroy, pm)
      assert ability.can?(:destroy, own_pm)
      assert ability.cannot?(:update, m2)
      assert ability.cannot?(:destroy, m2)
      assert ability.cannot?(:update, pm2)
      assert ability.cannot?(:destroy, pm2)
    end
  end

  test "owner permissions for team" do
    t2 = create_team
    tu_test = create_team_user team: t2, role: 'owner'
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, Team)
      assert ability.can?(:update, t)
      assert ability.can?(:destroy, t)
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
      assert ability.can?(:create, TeamUser)
      assert ability.can?(:update, tu2)
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
      assert ability.can?(:create, Contact)
      assert ability.can?(:update, c)
      assert ability.can?(:destroy, c)
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
      assert ability.can?(:update, u)
      assert ability.can?(:destroy, u)
      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

      tu_test1.update_column(:role, 'journalist')

      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

      tu_test1.update_column(:role, 'contributor')

      assert ability.can?(:update, u_test1)
      assert ability.can?(:destroy, u_test1)

      assert ability.cannot?(:update, u2_test)
      assert ability.cannot?(:destroy, u2_test)
    end
  end

  test "owner permissions for comment" do
    p = create_project team: t
    pm = create_project_media project: p
    mc = create_comment
    pm.add_annotation mc

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, Comment)
      assert ability.can?(:update, mc)
      assert ability.can?(:destroy, mc)
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
      assert_raise RuntimeError do
        c.save
      end
      assert_raise RuntimeError do
        c.destroy
      end
    end

    tu.role = 'owner'; tu.save!

    with_current_user_and_team(u) do
      assert_raise RuntimeError do
        c.save
      end
    end

    Rails.cache.clear
    c.text = 'for testing';c.save!
    assert_equal c.text, 'for testing'

    with_current_user_and_team(u) do
      assert_nothing_raised RuntimeError do
        c.destroy
      end
    end
  end

  test "owner permissions for flag" do
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    f = create_flag flag: 'Mark as graphic', annotator: u, annotated: pm

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, f)
      f.flag = 'Graphic content'
      assert ability.can?(:create, f)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, f)
    end
  end

  test "owner permissions for status" do
    p = create_project team: t
    m = create_valid_media
    pm = create_project_media project: p, media: m
    s = create_status status: 'verified', annotated: pm

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, s)
      assert ability.can?(:update, s)
      assert ability.can?(:destroy, s)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, s)
      assert ability.cannot?(:destroy, s)
    end
  end

  test "owner permissions for embed" do
    p = create_project team: t
    pm = create_project_media project: p
    em = create_embed annotated: pm

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, em)
      assert ability.can?(:update, em)
      assert ability.can?(:destroy, em)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:destroy, em)
    end
  end

  test "owner permissions for tag" do
    p = create_project team: t
    pm = create_project_media project: p
    tg = create_tag tag: 'media_tag', annotated: pm

    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, tg)
      assert ability.cannot?(:update, tg)
      assert ability.can?(:destroy, tg)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tg)
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

  test "should read source without user" do
    s = create_source user: nil
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:read, s)
    end
  end

  test "should read own source" do
    s = create_source user: u
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:read, s)
    end
  end

  test "should not read source from other user" do
    s = create_source user: create_user
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.cannot?(:read, s)
    end
  end

  test "should owner destroy annotation from any project from his team" do
    p1 = create_project team: t
    p2 = create_project team: t
    pm1 = create_project_media project: p1
    pm2 = create_project_media project: p2
    a1 = create_annotation annotated: pm1
    a2 = create_annotation annotated: pm2
    a3 = create_annotation annotated: create_project_media
    with_current_user_and_team(u) do
      a = AdminAbility.new
      assert a.can?(:destroy, a1)
      assert a.can?(:destroy, a2)
      assert a.cannot?(:destroy, a3)
    end
  end

  test "should owner destroy annotation versions" do
    p = create_project team: t
    pm = create_project_media project: p
    with_current_user_and_team(u) do
      s = create_status annotated: pm, status: 'verified'
      em = create_embed annotated: pm
      s_v = s.versions.last
      em_v = em.versions.last
      ability = AdminAbility.new
      # Status versions
      assert ability.can?(:create, s_v)
      assert ability.cannot?(:update, s_v)
      assert ability.can?(:destroy, s_v)
      # Embed versions
      assert ability.can?(:create, em_v)
      assert ability.cannot?(:update, em_v)
      assert ability.can?(:destroy, em_v)
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
      assert ability.can?(:create, tk)
      p.update_column(:team_id, nil)
      assert ability.cannot?(:create, tk)
    end
  end

  test "owner permissions for dynamic annotation" do
    p = create_project team: t
    pm = create_project_media project: p
    da = create_dynamic_annotation annotated: pm
    own_da = create_dynamic_annotation annotated: pm, annotator: u
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:create, Dynamic)
      assert ability.can?(:update, da)
      assert ability.can?(:destroy, da)
      assert ability.can?(:update, own_da)
      assert ability.can?(:destroy, own_da)
    end
  end

  test "owner permissions for export project data" do
    p = create_project team: t
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:export_project, Project)
    end
  end

  test "owner permissions to task" do
    task = create_task annotator: u
    create_annotation_type annotation_type: 'response'
    task.response = { annotation_type: 'response', set_fields: {} }.to_json
    task.save!
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:update, Task)
      assert ability.can?(:update, task)
    end
  end

  test "owner permissions to dynamic annotation" do
    task = create_task annotator: u
    dynamic_field = create_field annotation_id: task.id
    with_current_user_and_team(u) do
      ability = AdminAbility.new
      assert ability.can?(:update, DynamicAnnotation::Field)
      assert ability.can?(:update, dynamic_field)
    end
  end

end
