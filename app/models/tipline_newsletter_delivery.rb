class TiplineNewsletterDelivery < ApplicationRecord
  class TiplineNewsletterDeliveryError < StandardError; end

  belongs_to :tipline_newsletter
end
