require_relative '../test_helper'

class MontageTeamTest < ActiveSupport::TestCase
  test "should return project privacy" do
    team = create_team(private: true).extend(Montage::Project)
    assert_equal 1, team.privacy_project
    team = create_team(private: false).extend(Montage::Project)
    assert_equal 2, team.privacy_project
  end

  test "should return tags privacy" do
    team = create_team(private: true).extend(Montage::Project)
    assert_equal 1, team.privacy_tags
    team = create_team(private: false).extend(Montage::Project)
    assert_equal 2, team.privacy_tags
  end

  test "should return number of videos" do
    pender_url = CONFIG['pender_url_private'] + '/api/medias'
    team = create_team.extend(Montage::Project)
    assert_equal 0, team.video_count
    p = create_project team: team
    3.times { create_project_media(project: p) }
    3.times do |i|
      url = random_url
      response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      l = create_link url: url
      create_project_media project: p, media: l
    end
    3.times do |i|
      url = 'https://www.youtube.com/watch?v=' + random_string
      response = '{"type":"media","data":{"url":"' + url + '","type":"item"}}'
      WebMock.stub_request(:get, pender_url).with({ query: { url: url } }).to_return(body: response)
      l = create_link url: url
      create_project_media project: p, media: l
    end
    3.times { create_project_media }
    assert_equal 3, team.video_count
  end

  test "should return number of tags" do
    team = create_team.extend(Montage::Project)
    assert_equal 0, team.video_count
    p = create_project team: team
    3.times do
      pm = create_project_media project: p
      2.times { create_tag(annotated: pm) }
      2.times { create_comment(annotated: pm) }
      pm = create_project_media
      2.times { create_tag(annotated: pm) }
      2.times { create_comment(annotated: pm) }
    end
    assert_equal 6, team.video_tag_instance_count
  end

  test "should return the admin ids and user ids" do
    team = create_team.extend(Montage::Project)
    u1 = create_user
    u2 = create_user
    u3 = create_user
    u4 = create_user
    u5 = create_user
    create_team_user team: team, user: u1, status: 'member', role: 'owner'
    create_team_user team: team, user: u2, status: 'member', role: 'owner'
    create_team_user team: team, user: u3, status: 'member', role: 'editor'
    create_team_user team: team, user: u4, status: 'member', role: 'journalist'
    create_team_user team: team, user: u5, status: 'requested', role: 'owner'
    assert_equal [u1.id, u2.id].sort, team.admin_ids.sort
    assert_equal [u1.id, u2.id, u3.id, u4.id].sort, team.assigned_user_ids.sort
  end

  test "should return team as a Montage project JSON" do
    team = create_team.extend(Montage::Project)
    team_user = create_team_user(team: team, role: 'owner').extend(Montage::ProjectUser)
    assert_kind_of Hash, team.team_as_montage_project_json(team_user)
  end
end 
