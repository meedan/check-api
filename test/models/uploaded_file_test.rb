require_relative '../test_helper'

class UploadedFileTest < ActiveSupport::TestCase
  test "should create file" do
    assert_difference 'UploadedFile.count' do
      create_uploaded_file
    end
  end

  test "should not upload unsafe file (real)" do
    unless CONFIG['clamav_service_path'].blank?
      assert_no_difference 'UploadedFile.count' do
        assert_raises ActiveRecord::RecordInvalid do
          create_uploaded_file file: 'unsafe.txt'
        end
      end
    end
  end

  test "should upload safe file (real)" do
    unless CONFIG['clamav_service_path'].blank?
      assert_difference 'UploadedFile.count' do
        create_uploaded_file
      end
    end
  end

  test "should get file max size" do
    s =  UploadedFile.get_max_size({env: "1000000"})
    assert_equal Float, s.class
  end
end
