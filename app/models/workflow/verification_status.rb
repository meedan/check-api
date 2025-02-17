class Workflow::VerificationStatus < Workflow::Base

  check_default_project_media_workflow

  check_workflow from: :any, to: :any, actions: [:check_if_item_is_published, :apply_rules, :update_report_design_if_needed, :replicate_status_to_children]
  check_workflow on: :create, actions: :index_on_es_background
  check_workflow on: :update, actions: :index_on_es_foreground

  def self.core_default_value
    'undetermined'
  end

  def self.core_active_value
    'in_progress'
  end

  ProjectMedia.class_eval do
    alias_method :custom_permissions_original, :custom_permissions

    def custom_permissions(ability = nil)
      perms = self.custom_permissions_original
      ability ||= Ability.new
      perms["update Status"] = ability.can?(:update, Dynamic.new(annotation_type: 'verification_status', annotated: self))
      perms
    end

    def self.core_status_ids
      YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)['MEDIA_CORE_VERIFICATION_STATUSES'].collect{ |st| st[:id] }
    end

    def custom_statuses
      settings = self.team.settings
      settings = settings.permit('media_verification_statuses') if settings.is_a?(ActionController::Parameters) # Legacy from Rails 4
      statuses = settings.to_h.with_indifferent_access['media_verification_statuses']
      statuses = statuses.permit('statuses') if statuses.is_a?(ActionController::Parameters) # Legacy from Rails 4
      statuses.to_h.with_indifferent_access['statuses'].to_a
    end

    def custom_status_ids
      self.custom_statuses.collect{ |st| st[:id] }
    end

    def status_ids
      self.custom_status_ids.blank? ? ProjectMedia.core_status_ids : self.custom_status_ids
    end

    def status_i18n(key = nil, options = {})
      key ||= self.last_status
      core_status_ids = ProjectMedia.core_status_ids
      custom_statuses = self.custom_statuses
      if core_status_ids.include?(key.to_s) && custom_statuses.blank?
        I18n.t('statuses.media.' + key.to_s.gsub(/^false$/, 'not_true') + '.label', **options)
      else
        default_language = self.team.default_language
        language = options[:locale] || I18n.locale
        default = nil
        label = nil
        custom_statuses.each do |s|
          if s['id'].to_s == key.to_s
            default = s.dig('locales', default_language, 'label')
            label = s.dig('locales', language, 'label')
          end
        end
        label.blank? ? default : label
      end
    end
  end

  DynamicAnnotation::Field.class_eval do
    protected

    def apply_rules
      status = self.annotation&.load
      team = status.team
      if !team.nil? && status.annotated_type == 'ProjectMedia'
        # Evaluate only the rules that contain a condition that matches this status
        rule_ids = team.get_rules_that_match_condition do |condition, value|
          condition == 'status_is' && self.field_name == 'verification_status_status' && self.value == value
        end
        team.apply_rules_and_actions(status.annotated, rule_ids)
      end
    end

    def check_if_item_is_published
      return if self.bypass_status_publish_check
      published = begin (self.annotation.annotated.get_annotations('report_design').last.load.get_field_value('state') == 'published') rescue false end
      if published
        error = {
          message: I18n.t(:cant_change_status_if_item_is_published),
          code: LapisConstants::ErrorCodes::const_get('PUBLISHED_REPORT'),
          data: {
            type: 'media',
            id: self.annotation.annotated_id,
          }
        }
        raise error.to_json
      end
    end

    def update_report_design_if_needed
      pm = self.annotation.annotated
      report = pm.get_annotations('report_design').last
      unless report.nil?
        report = report.load
        data = report.data.clone.with_indifferent_access
        data[:options].merge!({
          theme_color: pm.last_status_color,
          status_label: pm.status_i18n(pm.last_verification_status, { locale: data[:options][:language] })
        })
        report.data = data
        report.save!
        # update FactCheck rating
        fc = pm&.claim_description&.fact_check
        if !fc.nil? && fc.rating != self.value
          fc.skip_report_update = true
          fc.skip_check_ability = true
          fc.rating = self.value
          fc.save!
        end
      end
    end

    def replicate_status_to_children
      Relationship.delay_for(1.second, { queue: 'smooch', retry: 0 }).replicate_status_to_children(self.annotation.annotated_id, User.current&.id, Team.current&.id)
    end
  end

  Team.class_eval do
    def get_media_verification_statuses
      settings = self.settings || {}
      settings.with_indifferent_access[:media_verification_statuses]
      custom_statuses = settings.with_indifferent_access[:media_verification_statuses]
      return custom_statuses unless custom_statuses.is_a?(Hash)
      if custom_statuses
        custom_statuses.with_indifferent_access['statuses'].to_a.each do |s|
          s[:label] = ProjectMedia.new(team: self).status_i18n(s[:id], { locale: self.get_language }) # Return label in current language
        end
      end
      custom_statuses
    end
  end
end
