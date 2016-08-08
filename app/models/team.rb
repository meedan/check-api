class Team < ActiveRecord::Base
  attr_accessible
  has_paper_trail on: [:create, :update]
  has_many :projects
  has_many :accounts
  has_many :team_users
  has_many :users, through: :team_users
  has_many :contacts

  mount_uploader :logo, ImageUploader
  validates_presence_of :name, :description

  after_create :add_user_to_team

  has_annotations

  def logo_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  private

  def add_user_to_team
    unless self.current_user.nil?
      tu = TeamUser.new
      tu.user = self.current_user
      tu.team = self
      tu.save!
    end
  end

end
