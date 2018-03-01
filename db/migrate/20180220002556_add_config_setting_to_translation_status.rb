class AddConfigSettingToTranslationStatus < ActiveRecord::Migration
  def change
    fi = DynamicAnnotation::FieldInstance.where(name: 'translation_status_status').last
    unless fi.nil?
      core_statuses = YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)
      fi.settings[:statuses] = core_statuses["MEDIA_CORE_TRANSLATION_STATUSES"]
      fi.save!
    end
  end
end
