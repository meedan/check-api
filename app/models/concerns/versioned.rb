require 'active_support/concern'

module Versioned
  extend ActiveSupport::Concern

  included do
    has_paper_trail on: [:create, :update], save_changes: true, ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }
  end
end
