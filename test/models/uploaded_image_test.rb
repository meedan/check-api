require_relative '../test_helper'

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
    stub_configs({ 'clamav_service_path' => 'localhost:8080' }) do
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
    stub_configs({ 'clamav_service_path' => 'localhost:8080' }) do
      ClamAV::Client.stubs(:new).returns(MockedClamavClient.new('success'))
      assert_difference 'UploadedImage.count' do
        create_uploaded_image
      end
      ClamAV::Client.unstub(:new)
    end
  end

  test "should return public_path as media url" do
    t = create_uploaded_image
    assert_equal t.file.url, t.media_url
    assert_equal t.public_path, t.media_url
  end

  test "should return a list of white-listed extensions" do
    assert_kind_of Array, ImageUploader.new.extension_white_list
  end

  test "should work on S3" do
    ft = create_field_type field_type: 'image_path', label: 'Image Path'
    at = create_annotation_type annotation_type: 'reverse_image', label: 'Reverse Image'
    create_field_instance annotation_type_object: at, name: 'reverse_image_path', label: 'Reverse Image', field_type_object: ft, optional: false
    i = create_uploaded_image
    pm = create_project_media media: i
    assert_match /^http/, pm.media.picture
  end

  test "should create image with accents in its name" do
    assert_difference 'UploadedImage.count' do
      create_uploaded_image file: 'maçã.png'
    end
  end
end
