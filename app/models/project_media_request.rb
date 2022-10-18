class ProjectMediaRequest < ApplicationRecord
  belongs_to :project_media
  belongs_to :request

  after_create :update_request_fact_checked_by, :update_request_project_medias_count

  private

  def update_request_fact_checked_by
    self.request.fact_checked_by(true)
  end

  def update_request_project_medias_count
    request = self.request
    request.update_column(:project_medias_count, ProjectMediaRequest.where(request_id: request.id).count)
    root_request = request.similar_to_request
    root_request.update_column(:project_medias_count, ProjectMediaRequest.where(request_id: root_request.similar_requests.map(&:id).concat([root_request.id])).count) unless root_request.nil?
  end
end
