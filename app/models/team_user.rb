class TeamUser < ActiveRecord::Base
  attr_accessible

  belongs_to :team
  belongs_to :user

  validates :status, presence: true
  validates :status, inclusion: { in: %w(member requested invited banned),
    message: "%{value} is not a valid team member status" }
  validates :role, inclusion: { in: %w(admin owner editor journalist contributor),
    message: "%{value} is not a valid team role" }
  validates :user_id, uniqueness: { scope: :team_id, message: "User already joined this team" }

  before_validation :set_role_default_value, on: :create

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def as_json(_options = {})
    {
      id: self.team.id,
      name: self.team.name,
      role: self.role,
      status: self.status
    }
  end

  private

  def set_role_default_value
    self.role = 'contributor' if self.role.nil?
  end

end
