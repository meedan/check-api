require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :project_mapping

    def self.duplicate(t)
      team = t.dup
      team.generate_slug
      File.open(t.logo.path) { |f| team.logo = f }
      team.copy_projects(t)
      team.copy_contacts(t)
      team.save!

      team.update_team_checklist
      team.copy_team_users(t)
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
      image = project.lead_image.path
      File.open(image) { |f| p.lead_image = f } if image
      p.token = nil
      self.project_mapping[project.id] = p
      self.projects << p
    end
  end

  def update_team_checklist
    return if self.get_checklist.blank?
    self.get_checklist.each do |task|
      task[:projects].map! { |p| self.project_mapping[p] ? self.project_mapping[p].id : p } if task[:projects]
    end
    self.save
  end

  def copy_team_users(t)
    t.team_users.each do |tu|
      self.team_users << tu.dup
    end
  end

  def copy_contacts(t)
    t.contacts.each do |c|
      self.contacts << c.dup
    end
  end

end
