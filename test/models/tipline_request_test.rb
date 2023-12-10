require_relative '../test_helper'

class TiplineRequestTest < ActiveSupport::TestCase
  test "should create tipline request" do
    assert_difference 'TiplineRequest.count' do
      create_tipline_request
    end
    # validate smooch_request_type, language and platform
    assert_raises ActiveRecord::RecordInvalid do
      create_tipline_request smooch_request_type: nil, smooch_data: { language: 'en', authorId: random_string, source: { type: 'whatsapp' } }
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_tipline_request smooch_data: { authorId: random_string, source: { type: 'whatsapp' } }
    end
    assert_raises ActiveRecord::RecordInvalid do
      create_tipline_request smooch_data: { language: 'en', authorId: random_string }
    end
    # validate smooch_request_type and platform values
    assert_no_difference 'TiplineRequest.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_request smooch_request_type: 'invalid_type'
      end
    end
    assert_no_difference 'TiplineRequest.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_tipline_request smooch_data: { language: 'en', authorId: random_string, source: { type: random_string } }
      end
    end
  end

  test "should set user and team" do
    t = create_team
    u = create_user
    create_team_user team: t, user: u, role: 'admin'
    with_current_user_and_team(u, t) do
      tr = create_tipline_request team_id: nil
      assert_equal t.id, tr.team_id
      assert_equal u.id, tr.user_id
    end
  end

  test "should set smooch data fields" do
    author_id = random_string
    platform = 'whatsapp'
    smooch_data = { language: 'en', authorId: author_id, source: { type: platform } }
    tr = create_tipline_request smooch_data: smooch_data
    assert_equal 'en', tr.language
    assert_equal author_id, tr.tipline_user_uid
    assert_equal platform, tr.platform
  end

  test "should get associated GraphQL ID" do
    tr = create_tipline_request
    assert_kind_of String, tr.associated_graphql_id
  end
end
