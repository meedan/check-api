require File.join(File.expand_path(File.dirname(__FILE__)), '..', 'test_helper')

class MachineTranslationWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.fake!
  end

  test "should add machine translation in background" do
    # MachineTranslationWorker.drain
    # assert_equal 1, MachineTranslationWorker.jobs.size
  end

end
