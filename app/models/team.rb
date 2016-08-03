class Team < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :team_users
  has_many :users, through: :team_users
  mount_uploader :logo, ImageUploader
  validates_presence_of :name, :description
  #after_create :set_creator_as_team_owner

  has_annotations

  def set_creator_as_team_owner
    tu = TeamUser.new
    tu.user = current_user
    tu.team = self
    tu.role = 'owner'
    tu.save!
  end

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end
end
