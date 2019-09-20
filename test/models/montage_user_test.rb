require_relative '../test_helper'

class MontageUserTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user(name: 'Foo Bar', login: 'foo_bar', is_admin: false).extend(Montage::User)
  end

  test "should return when the user was created" do
    assert_kind_of String, @user.date_joined
  end

  test "should return if the user accepted the terms" do
    assert !@user.accepted_nda
    @user.last_accepted_terms_at = Time.now
    @user.save!
    assert @user.accepted_nda
  end

  test "should return user first name" do
    assert_equal 'Foo', @user.first_name
  end

  test "should return user last name" do
    assert_equal 'Bar', @user.last_name
  end

  test "should return if the user is a super user" do
    assert !@user.is_superuser
    @user.is_admin = true
    @user.save!
    assert @user.is_superuser
  end

  test "should return the last time the user logged in" do
    assert_kind_of String, @user.last_login
  end

  test "should return the profile image URL" do
    assert_match /^http/, @user.profile_img_url
  end

  test "should return the username" do
    assert_equal 'foo_bar', @user.username
  end

  test "should return number of tags added by user" do
    u = create_user is_admin: true
    t = create_team
    create_team_user user: u, team: t
    p = create_project team: t
    pm = create_project_media project: p
    3.times { create_tag(annotated: pm) }
    3.times { create_tag }
    with_current_user_and_team(u, t) do
      3.times { create_tag(annotated: pm) }
    end
    assert_equal 3, u.reload.extend(Montage::User).tags_added
  end
end 
