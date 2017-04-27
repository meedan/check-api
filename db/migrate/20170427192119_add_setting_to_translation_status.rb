class AddSettingToTranslationStatus < ActiveRecord::Migration
  def change
    fi = DynamicAnnotation::FieldInstance.where(name: 'translation_status_status').last
    unless fi.nil?
      settings = fi.settings.clone
      settings[:statuses] = []
      settings[:options_and_roles].keys.each do |status|
        status = status.to_s
        settings[:statuses] << {
          description: status.humanize,
          id: status,
          label: status.humanize,
          style: ''
        }
      end
      fi.settings = settings
      fi.save!
    end
  end
end
