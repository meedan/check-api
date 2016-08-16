require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class ContactTest < ActiveSupport::TestCase

  test "should create contact" do
    assert_difference 'Contact.count' do
      create_contact
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
