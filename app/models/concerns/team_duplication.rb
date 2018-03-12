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
            self.set_mapping(original, copy)
            self.copy_image(original, copy)
            self.versions_log_mapping(original, copy)
          end
          team.is_being_copied = true
          team.save!
          team.update_team_checklist(@mapping[:Project])
          self.copy_annotations
          self.copy_versions(@mapping[:"PaperTrail::Version"])
          team
        end
      rescue StandardError => e
        Airbrake.notify(e) if Airbrake.configuration.api_key
        Rails.logger.error "[Team Duplication] Could not duplicate team #{t.slug}: #{e.message} #{e.backtrace.join("\n")}"
        nil
      end
    end

    def self.set_mapping(object, copy)
      key = object.class_name.to_sym
      @mapping[key] ||= {}
      @mapping[key][object.id] = copy
    end

    def self.copy_image(original, copy)
      [:logo, :lead_image, :file].each do |image|
        next unless original.respond_to?(image) && original.respond_to?("#{image}=") && original.send(image)
        img_path = original.send(image).path
        File.open(img_path) { |f| copy.send("#{image}=", f) } if img_path
      end
    end

    def self.versions_log_mapping(original, copy)
      if original.respond_to?(:get_versions_log)
        original.get_versions_log.find_each do |log|
          self.set_mapping(log, copy)
        end
      end
    end

    def self.copy_annotations
      [:ProjectMedia, :ProjectSource, :Source].each do |type|
        next if @mapping[type].blank?
        @mapping[type].each_pair do |original, copy|
          type.to_s.constantize.find(original).annotations.find_each do |a|
            a = a.load
            annotation = a.dup
            annotation.annotated = copy
            annotation.is_being_copied = true
            annotation.save!
            self.set_mapping(a, annotation)
            self.copy_annotation_fields(a, annotation, @mapping[:Task])
          end
        end
      end
    end

    def self.copy_annotation_fields(original, copy, task_mapping)
      original.get_fields.each do |f|
        field = f.dup
        field.annotation_id = copy.id
        field.value = task_mapping[f.value.to_i].id.to_s if field.field_type == "task_reference"
        field.save!
        self.set_mapping(f, field)
      end
    end

    def self.copy_versions(versions_mapping)
      return if versions_mapping.blank?
      PaperTrail::Version.skip_callback(:create, :after, :increment_project_association_annotations_count)
      versions_mapping.each_pair do |original, copy|
        log = PaperTrail::Version.find(original).dup
        log.associated_id = copy.id
        log.item_id = @mapping[log.item_type.to_sym][log.item_id.to_i].id.to_s
        log.save!
      end
      PaperTrail::Version.set_callback(:create, :after, :increment_project_association_annotations_count)
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

  def reset_statuses(type)
    errors.delete(:statuses)
    self.send("reset_#{type}_verification_statuses")
  end
end
