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
            self.copy_image(original, copy)
          end
          team.is_being_copied = true
          team.save!
          team.update_team_checklist(@mapping[:Project])
          self.copy_annotations(@mapping)
          team
        end
      rescue StandardError => e
        Airbrake.notify(e) if Airbrake.configuration.api_key
        Rails.logger.error "[Team Duplication] Could not duplicate team #{t.slug}: #{e.message}"
        nil
      end
    end

    def self.copy_image(original, copy)
      [:logo, :lead_image, :file].each do |image|
        next unless original.respond_to?(image) && original.respond_to?("#{image}=") && original.send(image)
        img_path = original.send(image).path
        File.open(img_path) { |f| copy.send("#{image}=", f) } if img_path
      end
    end

    def self.copy_annotations(mapping)
      [:ProjectMedia, :ProjectSource, :Source].each do |type|
        next if mapping[type].blank?
        mapping[type].each_pair do |original, copy|
          type.to_s.constantize.find(original).annotations.find_each do |a|
            a = a.load
            annotation = a.dup
            annotation.annotated = copy
            annotation.save!
            mapping[a.class_name.to_sym] ||= {}
            mapping[a.class_name.to_sym][a.id] = annotation.id
            self.copy_annotation_fields(a, annotation, mapping[:Task])
          end
        end
      end
    end

    def self.copy_annotation_fields(original, copy, task_mapping)
      original.get_fields.each do |f|
        field = f.dup
        field.annotation_id = copy.id
        field.value = task_mapping[f.value.to_i].to_s if field.field_type == "task_reference"
        field.save!
      end
    end

  end

  def generate_copy_slug
    i = 1
    slug = ''
    loop do
      slug = self.slug + "-copy-#{i}"
      if slug.length > 63
        extra = slug.length - 63
        slug.remove!(slug[11..10+extra])
      end
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

end
