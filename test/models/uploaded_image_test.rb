require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class UploadedImageTest < ActiveSupport::TestCase
  test "should create image" do
    assert_difference 'UploadedImage.count' do
      create_uploaded_image
    end
  end

  test "should not upload a file that is not an image" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: 'not-an-image.txt'
      end
    end
  end

  test "should not upload a big image" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: 'ruby-big.png'
      end
    end
  end

  test "should not upload a small image" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: 'ruby-small.png'
      end
    end
  end

  test "should not create image without file" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: nil
      end
    end
  end

  test "should have public path" do
    t = create_uploaded_image
    assert_match /^http/, t.public_path
  end

  test "should not upload a heavy image" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: 'rails-photo.jpg'
      end
    end
  end
  
  test "should create versions" do
    i = create_uploaded_image
    assert_not_nil i.file.thumbnail
    assert_not_nil i.file.embed
  end

  test "should not upload corrupted file" do
    assert_no_difference 'UploadedImage.count' do
      assert_raises ActiveRecord::RecordInvalid do
        create_uploaded_image file: 'corrupted-image.png'
      end
    end
  end

  test "should not upload if disk is full" do
    UploadedImage.any_instance.stubs(:save!).raises(Errno::ENOSPC)
    assert_no_difference 'UploadedImage.count' do
      assert_raises Errno::ENOSPC do
        create_uploaded_image
      end
    end
    UploadedImage.any_instance.unstub(:save!)
  end

  test "should not upload unsafe image (mocked)" do
    stub_config('clamav_service_path', 'localhost:8080') do
      ClamAV::Client.stubs(:new).returns(MockedClamavClient.new('virus'))
      assert_no_difference 'UploadedImage.count' do
        assert_raises ActiveRecord::RecordInvalid do
          create_uploaded_image
        end
      end
      ClamAV::Client.unstub(:new)
    end
  end

  test "should upload safe image (mocked)" do
    stub_config('clamav_service_path', 'localhost:8080') do
      ClamAV::Client.stubs(:new).returns(MockedClamavClient.new('success'))
      assert_difference 'UploadedImage.count' do
        create_uploaded_image
      end
      ClamAV::Client.unstub(:new)
    end
  end

  test "should return public_path as media url" do
    t = create_uploaded_image
    assert_equal "#{CONFIG['checkdesk_base_url']}#{t.file.url}", t.media_url
    assert_equal t.public_path, t.media_url
  end

end
