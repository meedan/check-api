require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

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
    t = create_team current_user: u
    c = create_contact team: t, current_user: u
    c.current_user = u
    c.location = 'location'; c.save!
    c.reload
    assert_equal c.location, 'location'
    # update contact as editor
    u2 = create_user
    tu = create_team_user team: t, user: u2, role: 'editor'
    c.current_user = u2
    c.location = 'location_mod'; c.save!
    c.reload
    assert_equal c.location, 'location_mod'
    assert_raise RuntimeError do
      c.current_user = u2
      c.destroy
    end
    tu.role = 'journalist'; tu.save!
    assert_raise RuntimeError do
      c.current_user = u2
      c.save!
    end
  end

  test "should read contact" do
    u = create_user
    t = create_team current_user: create_user
    c = create_contact team: t
    pu = create_user
    pt = create_team current_user: pu, private: true
    pc = create_contact team: pt
    Contact.find_if_can(c.id, u, t)
    assert_raise CheckdeskPermissions::AccessDenied do
      Contact.find_if_can(pc.id, u, pt)
    end
    Contact.find_if_can(pc.id, pu, pt)
    tu = pt.team_users.last
    tu.status = 'requested'; tu.save!
    assert_raise CheckdeskPermissions::AccessDenied do
      Contact.find_if_can(pc.id, pu, pt)
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

end
