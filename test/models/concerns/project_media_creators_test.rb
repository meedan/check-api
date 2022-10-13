require 'test_helper'

class FakeProjectMediaCreators
  include ProjectMediaCreators

  def initialize(url)
    @url = url
  end

  def url
    @url
  end

  def team
    nil
  end
end

class ProjectMediaCreatorsTest < ActiveSupport::TestCase
  test "#create_link calls find with normalized URL" do
    Team.current = nil

    Link.stubs(:normalized).returns('https://example.com/new')
    Link.expects(:find_by).with(url: 'https://example.com/new').returns('fake link')

    fpc = FakeProjectMediaCreators.new('https://example.com/original')
    assert_equal 'fake link', fpc.send(:create_link)

    Link.unstub(:normalized)
    Link.unstub(:find_by)
  end

  test "#create_link calls create with original URL, to let Pender normalize it" do
    Team.current = nil
    create_url = nil

    Link.stubs(:find_by).returns(nil)
    Link.stubs(:normalized).returns('https://example.com/new')
    Link.expects(:create).with(url: 'https://example.com/original', pender_key: nil).returns('fake link')

    fpc = FakeProjectMediaCreators.new('https://example.com/original')
    assert_equal 'fake link', fpc.send(:create_link)

    Link.unstub(:find_by)
    Link.unstub(:normalized)
    Link.unstub(:create)
  end
end
