class TeamSource < ActiveRecord::Base
  belongs_to :team
  belongs_to :source
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validates_presence_of :team_id, :source_id
  validates :source_id, uniqueness: { scope: :team_id }

  private

  def set_user
  	self.user = User.current unless User.current.nil?
  end

end
