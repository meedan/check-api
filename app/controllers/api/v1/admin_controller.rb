class Api::V1::AdminController < ApplicationController

  # GET /api/admin/project/add_publisher?token=:project-token
  def add_publisher_to_project
    project = Project.find(params[:id])
    provider = params[:provider]
    auth = session["check.#{provider}.authdata"]
    if params[:token].to_s == project.token
      setting = (project.get_social_publishing || {}).clone
      setting[provider] = auth
      project.set_social_publishing(setting)
      project.skip_check_ability = true
      project.save!
      render text: I18n.t(:auto_publisher_added_to_project, project: project.title, provider: provider.capitalize)
    else
      render text: I18n.t(:invalid_token), status: 401
    end
  end
end
