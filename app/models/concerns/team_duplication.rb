require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :project_mapping, :source_mapping, :project_source_mapping, :project_media_mapping

    def self.duplicate(t)
      team = t.deep_clone include: [ { projects: [ :project_sources, :project_medias ] }, :team_users, :contacts, :sources ] do |original, copy|
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
        if copy.is_a? ProjectSource
          @project_source_mapping ||= {}
          @project_source_mapping[original.id] = copy
        end
        if copy.is_a? ProjectMedia
          @project_media_mapping ||= {}
          @project_media_mapping[original.id] = copy
        end
      end
      team.save!

      team.update_team_checklist(@project_mapping)
      team.update_project_sources(@source_mapping)
      team.copy_project_media_annotations(@project_media_mapping)
      team.copy_project_source_annotations(@project_source_mapping)
      team.copy_source_annotations(@source_mapping)
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

  def copy_project_media_annotations(mapping)
    copy_annotations(:project_media, mapping)
  end

  def copy_project_source_annotations(mapping)
    copy_annotations(:project_source, mapping)
  end

  def copy_source_annotations(mapping)
    copy_annotations(:source, mapping)
  end

  def copy_annotations(type, mapping)
    mapping.each_pair do |original, copy|
      type.to_s.capitalize.camelize.constantize.find(original).annotations.find_each do |a|
        next unless %w[comment dynamic embed flag geolocation status tag task].include?(a.annotation_type)
        a = a.annotation_type.classify.constantize.find(a.id)
        annotation = a.dup
        annotation.annotated = copy
        annotation.save
      end
    end
  end

end
