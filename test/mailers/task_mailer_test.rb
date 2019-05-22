require_relative '../test_helper'

class TaskMailerTest < ActionMailer::TestCase
  test "should send task answered notification" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotator: u, annotated: pm
    u2 = create_user
    create_team_user team: t, user: u2, role: 'editor'
    at = create_annotation_type annotation_type: 'response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    with_current_user_and_team(u2, t) do
      tk.response = { annotation_type: 'response', set_fields: { response_test: 'test' }.to_json }.to_json
      tk.save!
    end
    email = TaskMailer.notify(tk, tk.first_response_obj, tk.first_response, tk.status)
    assert_emails 1 do
      email.deliver_now
    end
  end
end
