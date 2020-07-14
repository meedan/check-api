module Workflow
  class Workflow
    def self.workflows
      [::Workflow::VerificationStatus, ::Workflow::TaskStatus]
    end

    def self.workflow_ids
      ::Workflow::Workflow.workflows.collect{ |w| w.name.gsub('Workflow::', '').underscore }
    end

    def self.is_field_name_a_workflow?(field_name)
      ::Workflow::Workflow.workflow_ids.include?(field_name.gsub(/_status$/, ''))
    end

    def self.core_options(annotated, annotation_type)
      klass = "Workflow::#{annotation_type.camelize}".constantize
      type = (annotated.class_name == 'ProjectMedia') ? 'media' : annotated.class_name
      core_statuses = YAML.load(ERB.new(File.read("#{Rails.root}/config/core_statuses.yml")).result)
      key = "#{type.upcase}_CORE_#{annotation_type.pluralize.upcase}"
      statuses = core_statuses.has_key?(key) ? core_statuses[key] : [{ id: 'undetermined', label: I18n.t(:"statuses.media.undetermined.label"), description: I18n.t(:"statuses.media.undetermined.description"), style: '' }]
      statuses = statuses.collect do |status|
        locales = {}
        I18n.available_locales.each do |locale|
          key = status[:id]
          locales[locale] = {
            label: I18n.t('statuses.media.' + key.to_s.gsub(/^false$/, 'not_true') + '.label', { locale: locale }),
            description: I18n.t('statuses.media.' + key.to_s.gsub(/^false$/, 'not_true') + '.description', { locale: locale })
          }
        end
        status.with_indifferent_access.merge({ locales: locales })
      end
      {
        label: 'Status',
        default: klass.core_default_value,
        active: klass.core_active_value,
        statuses: statuses
      }.with_indifferent_access
    end

    def self.options(annotated, annotation_type)
      type = (annotated.class_name == 'ProjectMedia') ? 'media' : annotated.class_name
      statuses = ::Workflow::Workflow.core_options(annotated, annotation_type)
      getter = "get_#{type.downcase}_#{annotation_type.pluralize}"
      team = annotated&.team
      custom_statuses = team&.send(getter)
      custom_statuses || statuses
    end

    def self.get_status(annotated, annotation_type, id)
      statuses = ::Workflow::Workflow.options(annotated, annotation_type)[:statuses]
      return statuses.select{ |st| st['id'] == id }&.first
    end

    include ::Workflow::Concerns::CheckSearchConcern
    include ::Workflow::Concerns::DynamicAnnotationFieldConcern
    include ::Workflow::Concerns::DynamicConcern
    include ::Workflow::Concerns::MediaSearchConcern
    include ::Workflow::Concerns::TargetConcern
    include ::Workflow::Concerns::TeamConcern
  end
end
