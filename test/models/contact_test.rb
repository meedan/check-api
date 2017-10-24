require_relative '../test_helper'

class ContactTest < ActiveSupport::TestCase

  test "should create contact" do
    assert_difference 'Contact.count' do
      create_contact
    end
    assert_difference 'Contact.count' do
      u = create_user
      t = create_team current_user: u
      create_contact team: t, current_user: u
    end
  end

  test "should update and destroy contact" do
    u = create_user
    t = create_team
    create_team_user user: u, team: t, role: 'owner'
    c = create_contact team: t
    with_current_user_and_team(u, t) do
      c.location = 'location'; c.save!
    end
    c.reload
    assert_equal c.location, 'location'
    # update contact as editor
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    with_current_user_and_team(u2, t) do
      c.location = 'location_mod'; c.save!
    end
    c.reload
    assert_equal c.location, 'location_mod'
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) do
        c.destroy
      end
    end
    Rails.cache.clear
    u2 = User.find(u2.id)
    tu.role = 'journalist'; tu.save!
    assert_raise RuntimeError do
      with_current_user_and_team(u2, t) do
        c.save!
      end
    end
  end

  test "non members should not read contact in private team" do
    u = create_user
    t = create_team
    create_team_user team: t, user: u, role: 'owner'
    c = create_contact team: t
    pu = create_user
    pt = create_team private: true
    create_team_user team: pt, user: pu, role: 'owner'
    pc = create_contact team: pt
    with_current_user_and_team(u, t) { Contact.find_if_can(c.id) }
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(u, pt) { Contact.find_if_can(pc.id) }
    end
    with_current_user_and_team(pu, pt) { Contact.find_if_can(pc.id) }
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckPermissions::AccessDenied do
      with_current_user_and_team(pu.reload, pt) { Contact.find_if_can(pc.id) }
    end
  end

  test "should relate contacts to team" do
    t = create_team
    c1 = create_contact team: t
    c2 = create_contact team: t
    c3 = create_contact
    assert_kind_of Team, c1.team
    assert_equal [c1.id, c2.id].sort, t.reload.contacts.map(&:id).sort
  end

  test "should not create contact with invalid phone number" do
    assert_no_difference 'Contact.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_contact phone: "invalid"
      end
    end
  end

  test "should protect attributes from mass assignment" do
    raw_params = { phone: random_valid_phone }
    params = ActionController::Parameters.new(raw_params)

    assert_raise ActiveModel::ForbiddenAttributesError do
      Contact.create(params)
    end
  end

end
