require_relative '../test_helper'

class TaskMailerTest < ActionMailer::TestCase
	test "should send task answered notification" do
		u = create_user
		t = create_task user: u
    assert_equal 'unresolved', t.reload.status
    at = create_annotation_type annotation_type: 'response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    t.response = { annotation_type: 'response', set_fields: { response_test: 'test' }.to_json }.to_json
    t.save!
    email = TaskMailer.notify(t, u)
    # assert_emails 1 do
    #   email.deliver_now
    # end
  end
end
