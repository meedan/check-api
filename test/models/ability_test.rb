require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class AbilityTest < ActiveSupport::TestCase

  test "contributor permissions for project" do
    u = create_user(role: 'contributor')
    u.save
    ability = Ability.new(u)
    assert !ability.can?(:create, Project)
    p = create_project
    assert !ability.can?(:update, p)
    own_project = create_project(user_id: u.id)
    assert !ability.can?(:update, own_project)
    assert !ability.can?(:destroy, p)
    assert !ability.can?(:destroy, own_project)
  end

  test "journalist permissions for project" do
    u = create_user(role: 'journalist')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Project)
    p = create_project
    #assert ability.can?(:update, [title: 'testCing'] ,p)
    own_project = create_project(user_id: u.id)
    assert !ability.can?(:destroy, p)
    assert !ability.can?(:destroy, own_project)

  end

  test "editor permissions for project" do
    u = create_user(role: 'editor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Project)
    p = create_project
    #assert ability.can?(:update, [title: 'testCing'] ,p)
    own_project = create_project(user_id: u.id)
    assert ability.can?(:destroy, p)
    assert ability.can?(:destroy, own_project)
  end

  test "contributor permissions for media" do
    u = create_user(role: 'contributor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    m = create_valid_media
    assert !ability.can?(:update, m)
    own_media = create_valid_media(user_id: u.id)
    assert ability.can?(:update, own_media)
    assert !ability.can?(:destroy, m)
    assert !ability.can?(:destroy, own_media)
  end

  test "journalist permissions for media" do
    u = create_user(role: 'journalist')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    m = create_valid_media
    assert ability.can?(:update, m)
    own_media = create_valid_media(user_id: u.id)
    assert ability.can?(:update, own_media)
    assert !ability.can?(:destroy, m)
    assert !ability.can?(:destroy, own_media)
  end

  test "editor permissions for media" do
    u = create_user(role: 'editor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Media)
    m = create_valid_media
    assert ability.can?(:update, m)
    own_media = create_valid_media(user_id: u.id)
    assert ability.can?(:update, own_media)
    assert ability.can?(:destroy, m)
    assert ability.can?(:destroy, own_media)
  end

  test "contributor permissions for source" do
    u = create_user(role: 'contributor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert !ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    #assert ability.can?(:update, own_source)
    assert !ability.can?(:destroy, s)
    assert !ability.can?(:destroy, own_source)
  end

  test "journalist permissions for source" do
    u = create_user(role: 'journalist')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    assert ability.can?(:update, own_source)
    assert !ability.can?(:destroy, s)
    assert !ability.can?(:destroy, own_source)
  end

  test "editor permissions for source" do
    u = create_user(role: 'editor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Source)
    s = create_source
    assert ability.can?(:update, s)
    own_source = create_source(user_id: u.id)
    assert ability.can?(:update, own_source)
    assert ability.can?(:destroy, s)
    assert ability.can?(:destroy, own_source)
  end

  test "contributor permissions for account" do
    u = create_user(role: 'contributor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert !ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert !ability.can?(:destroy, a)
    assert !ability.can?(:destroy, own_account)
  end

  test "journalist permissions for account" do
    u = create_user(role: 'journalist')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert !ability.can?(:destroy, a)
    assert !ability.can?(:destroy, own_account)
  end

  test "editor permissions for account" do
    u = create_user(role: 'editor')
    u.save
    ability = Ability.new(u)
    assert ability.can?(:create, Account)
    a = create_valid_account
    assert ability.can?(:update, a)
    own_account = create_valid_account(user_id: u.id)
    assert ability.can?(:update, own_account)
    assert ability.can?(:destroy, a)
    assert ability.can?(:destroy, own_account)
  end

end
