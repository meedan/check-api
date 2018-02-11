require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :project_mapping

    def self.duplicate(t)
      team = t.dup
      team.generate_slug
      team.copy_projects(t)
      team.save
      team.update_team_checklist
      team
    end
  end

  def generate_slug
    i = 1
    loop do
      slug = self.slug.concat("-copy-#{i}")
      break unless Team.find_by(slug: slug)
      i += 1
    end
  end

  def copy_projects(t)
    self.project_mapping = {}
    t.projects.each do |project|
      p = project.dup
      File.open(project.lead_image.path) do |f|
        p.lead_image = f
      end
      p.token = nil
      self.project_mapping[project.id] = p
      self.projects << p
    end
  end

  def update_team_checklist
    return if self.get_checklist.blank?
    self.get_checklist.each do |task|
      task[:projects] = task[:projects].map { |p| self.project_mapping[p] ? self.project_mapping[p].id : p }
    end
    self.save
  end

end
