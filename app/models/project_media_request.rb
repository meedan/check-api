class ProjectMediaRequest < ApplicationRecord
  belongs_to :project_media
  belongs_to :request

  after_create :update_request_fact_checked_by

  private

  def update_request_fact_checked_by
    self.request.fact_checked_by(true)
  end
end
