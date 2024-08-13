# Join model
class ExplainerItem < ApplicationRecord
  has_paper_trail on: [:create, :destroy], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  belongs_to :explainer
  belongs_to :project_media
  belongs_to :user

  before_validation :set_user

  validates_presence_of :explainer, :project_media
  validate :same_team

  private

  def same_team
    errors.add(:base, I18n.t(:explainer_and_item_must_be_from_the_same_team)) unless self.explainer&.team_id == self.project_media&.team_id
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end
end
