require_relative '../test_helper'

class CheckS3Test < ActiveSupport::TestCase
  def setup
  end

  test "should return resource" do
    assert_kind_of Aws::S3::Resource, CheckS3.resource
  end

  test "should return bucket" do
    assert_not_nil CheckS3.bucket
  end

  test "should manage files in S3" do
    path = 'test/test.txt'
    CheckS3.delete(path) if CheckS3.exist?(path)
    assert !CheckS3.exist?(path)
    assert_nil CheckS3.read(path)
    assert_nil CheckS3.get(path)
    CheckS3.write(path, 'text/plain', 'Test')
    assert CheckS3.exist?(path)
    assert_equal 'Test', CheckS3.read(path)
    assert_not_nil CheckS3.get(path)
    assert_match /^http/, CheckS3.public_url(path)
    CheckS3.delete(path)
    assert !CheckS3.exist?(path)
    assert_nil CheckS3.read(path)
    assert_nil CheckS3.get(path)
  end
end
