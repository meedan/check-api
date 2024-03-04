require_relative '../test_helper'

class TermsOfServiceUpdateWorkerTest < ActiveSupport::TestCase
  def setup
    super
    require 'sidekiq/testing'
    Sidekiq::Testing.inline!
  end
end
