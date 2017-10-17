require 'active_support/concern'

module TeamAssociations
  extend ActiveSupport::Concern
  
  included do
    has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }

    has_many :projects, dependent: :destroy
    has_many :accounts, dependent: :destroy
    has_many :team_users, dependent: :destroy
    has_many :users, through: :team_users
    has_many :contacts, dependent: :destroy
    has_many :sources, dependent: :destroy
  
    has_annotations
  end
end
