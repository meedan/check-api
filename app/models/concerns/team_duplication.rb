require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :project_mapping, :source_mapping

    def self.duplicate(t)
      team = t.deep_clone include: [ { projects: [ :project_sources, :project_medias] }, :team_users, :contacts, :sources ] do |original, copy|
        if copy.is_a? Team
          copy.logo = original.logo
          copy.generate_slug
        end
        if copy.is_a? Project
          copy.lead_image = original.lead_image
          copy.token = nil
          @project_mapping ||= {}
          @project_mapping[original.id] = copy
        end
        if copy.is_a? Source
          copy.file = original.file
          @source_mapping ||= {}
          @source_mapping[original.id] = copy
        end

      end
      team.save!

      team.update_team_checklist(@project_mapping)
      team.update_project_sources(@source_mapping)
      team
    end
  end

  def generate_slug
    i = 1
    loop do
      slug = self.slug + "-copy-#{i}"
      if Team.find_by(slug: slug)
        i += 1
      else
        self.slug = slug
        break
      end
    end
  end

  def update_team_checklist(project_mapping)
    return if self.get_checklist.blank?
    self.get_checklist.each do |task|
      task[:projects].map! { |p| project_mapping[p] ? project_mapping[p].id : p } if task[:projects]
    end
    self.save
  end

  def update_project_sources(source_mapping)
    self.projects.each do |project|
      project.project_sources.each do |ps|
        ps.source_id = source_mapping[ps.source_id] ? source_mapping[ps.source_id].id : ps.source_id
        ps.save
      end
    end
  end


end
