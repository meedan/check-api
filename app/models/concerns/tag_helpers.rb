require 'active_support/concern'

module TagHelpers
  extend ActiveSupport::Concern

  def clean_tags(tags)
    tags.map { |tag| tag.strip.gsub(/^#/, '') }.uniq
  end
end
