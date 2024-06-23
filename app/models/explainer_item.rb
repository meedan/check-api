# Join model
class ExplainerItem < ApplicationRecord
  belongs_to :explainer
  belongs_to :project_media

  validates_presence_of :explainer, :project_media
  validate :same_team

  private

  def same_team
    errors.add(:base, I18n.t(:explainer_and_item_must_be_from_the_same_team)) unless self.explainer&.team_id == self.project_media&.team_id
  end
end
