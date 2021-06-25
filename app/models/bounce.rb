# How to create a bounce from the command line: $ bundle exec rails runner "Bounce.create!(email: 'test@test.com')"
class Bounce < ApplicationRecord

  def self.remove_bounces(*recipients)
    recipients.flatten.reject{ |r| Bounce.where(email: r).exists? }
  end
end
