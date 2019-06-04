require_relative '../test_helper'

class TaskMailerTest < ActionMailer::TestCase
  test "should send task answered notification" do
    t = create_team slug: 'test'
    u = create_user
    create_team_user team: t, user: u, role: 'owner'
    owner2 = create_user
    create_team_user team: t, user: owner2, role: 'owner'
    # bounced one email to verify notification should not send to bounced email
    bounced = create_user
    create_team_user team: t, user: bounced, role: 'owner'
    create_bounce email: bounced.email
    p = create_project team: t
    pm = create_project_media project: p
    tk = create_task annotator: u, annotated: pm
    u1 = create_user
    create_team_user user: u1, team: t, role: 'editor'
    u2 = create_user
    create_team_user user: u2, team: t
    with_current_user_and_team(u1, t) do  
      tk.assigned_to_ids = u2.id
      tk.save!
    end
    at = create_annotation_type annotation_type: 'response'
    create_field_instance annotation_type_object: at, name: 'response_test'
    with_current_user_and_team(u2, t) do
      tk.response = { annotation_type: 'response', set_fields: { response_test: 'test' }.to_json }.to_json
      tk.save!
    end

    options = {
      task: tk,
      response: tk.first_response_obj,
      answer: tk.first_response,
      status: tk.status
    }

    emails = TaskMailer.send_notification(YAML::dump(options))
    assert_equal [u.email, owner2.email, u1.email].sort, emails.sort
  end
end
