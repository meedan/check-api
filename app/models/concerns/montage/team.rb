module Montage::Project
  include Montage::Base

  def privacy_project
    self.private ? 1 : 2
  end

  # FIXME: Assuming that that team privacy setting applies to tags
  def privacy_tags
    self.privacy_project
  end

  def video_count
    self.video.count
  end

  def video(project_id = nil)
    conditions = { 'projects.team_id' => self.id }
    conditions['projects.id'] = project_id if project_id.to_i > 0
    ProjectMedia.joins(:project).joins(:media).where(conditions).where("medias.url LIKE 'https://www.youtube.com%'")
  end

  def video_tag_instance_count
    Tag
    .joins("INNER JOIN project_medias ON project_medias.id = annotations.annotated_id INNER JOIN projects ON projects.id = project_medias.project_id")
    .where(annotation_type: 'tag')
    .where(annotated_type: 'ProjectMedia')
    .where('projects.team_id' => self.id)
    .count
  end

  def admin_ids
    self.team_users.where(role: 'owner', status: 'member').map(&:user_id)
  end

  def assigned_user_ids
    self.team_users.where(status: 'member').map(&:user_id)
  end

  def team_as_montage_project_json(team_user)
    owner = TeamUser.where(team_id: self.id, role: 'owner', status: 'member').first&.user&.extend(Montage::User)
    {
      admin_ids: self.admin_ids,
      assigned_user_ids: self.assigned_user_ids,
      created: self.created,
      current_user_info: team_user.as_current_user_info,
      description: self.description,
      id: self.id,
      modified: self.modified, 
      name: self.name,
      owner: {
        email: owner&.email,
        first_name: owner&.first_name, 
        id: owner&.id, 
        last_name: owner&.last_name, 
        profile_img_url: owner&.profile_img_url
      }, 
      privacy_project: self.privacy_project, 
      privacy_tags: self.privacy_tags, 
      video_tag_instance_count: self.video_tag_instance_count
    }
  end
end
