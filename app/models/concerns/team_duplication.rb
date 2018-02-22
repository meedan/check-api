require 'active_support/concern'

module TeamDuplication
  extend ActiveSupport::Concern

  included do
    attr_accessor :mapping

    def self.duplicate(t)
      @mapping = {}
      begin
        ActiveRecord::Base.transaction do
          team = t.deep_clone include: [ { projects: [ :project_sources, { project_medias: :versions } ] }, :team_users, :contacts, :sources ] do |original, copy|
            @mapping[original.class_name.to_sym] ||= {}
            @mapping[original.class_name.to_sym][original.id] = copy
            [:logo, :lead_image, :file].each do |image|
              next unless original.respond_to?(image) && original.respond_to?("#{image}=") && original.send(image)
              img_path = original.send(image).path
              File.open(img_path) { |f| copy.send("#{image}=", f) } if img_path
            end
          end
          team.is_being_copied = true
          team.save!
          team.update_team_checklist(@mapping[:Project])
          team.update_project_sources(@mapping[:Source])
          team.copy_annotations(@mapping)
          team
        end
      rescue StandardError => e
        Rails.logger.error "[Team Duplication] Could not duplicate team #{t.slug}: #{e.message}"
        nil
      end
    end
  end

  def generate_copy_slug
    i = 1
    slug = ''
    loop do
      slug = self.slug + "-copy-#{i}"
      break unless Team.find_by(slug: slug)
      i += 1
    end
    slug
  end

  def update_team_checklist(project_mapping)
    return if self.get_checklist.blank?
    self.get_checklist.each do |task|
      task[:projects].map! { |p| project_mapping[p] ? project_mapping[p].id : p } if task[:projects]
    end
    self.save!
  end

  def update_project_sources(source_mapping)
    return if source_mapping.nil?
    self.projects.each do |project|
      project.project_sources.each do |ps|
        ps.source_id = source_mapping[ps.source_id] ? source_mapping[ps.source_id].id : ps.source_id
        ps.save!
      end
    end
  end

  def copy_annotations(mapping)
    [:ProjectMedia, :ProjectSource, :Source].each do |type|
      next if mapping[type].blank?
      mapping[type].each_pair do |original, copy|
        type.to_s.constantize.find(original).annotations.find_each do |a|
          a = a.annotation_type_class.find(a.id)
          annotation = a.dup
          annotation.annotated = copy
          annotation.save!
        end
      end
    end
  end

end
