class Task < ActiveRecord::Base
  include AnnotationBase

  before_validation :set_initial_status, on: :create
  after_destroy :destroy_responses

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice']
  end
  validates :type, included: { values: self.task_types }

  field :description

  field :options
  validate :task_options_is_array

  field :status
  def self.task_statuses
    ["Unresolved", "Resolved", "Can't be resolved"]
  end
  validates :status, included: { values: self.task_statuses }, allow_blank: true

  annotation_notifies_slack :update
  annotation_notifies_slack :create

  def slack_message
    if self.versions.count > 1
      self.slack_message_on_update
    else
      self.slack_message_on_create
    end
  end

  def slack_message_on_create
    params = self.slack_default_params.merge({
      default: "*%{user}* created task <%{url}> in %{project} with note '%{note}'",
      note: self.description
    })
    I18n.t(:slack_create_task, params)
  end

  def slack_default_params
    {
      user: User.current.name,
      url: "#{self.annotated_client_url}|#{self.label.gsub(/\n/, ' ')}",
      project: self.annotated.project.title
    }
  end

  def slack_message_on_update
    if self.data_changed?
      data = self.data
      data_was = self.data_was
      messages = []

      {
        'label' => '*%{user}* edited task <%{url}> in %{project}:\n> *From:* %{from}\n> *To*: %{to}',
        'description' => '*%{user}* edited task note in <%{url}> in %{project}:\n> *From:* %{from}\n> *To*: %{to}'
      }.each do |key, message|
        if data_was[key] != data[key]
          params = self.slack_default_params.merge({
            default: message,
            from: data_was[key],
            to: data[key]
          })
          messages << I18n.t("slack_update_task_#{key}".to_sym, params)
        end
      end

      messages.join("\n")
    end
  end

  def content
    hash = {}
    %w(label type description options status).each{ |key| hash[key] = self.send(key) }
    hash.to_json
  end

  def jsonoptions=(json)
    @json = json
    self.options = JSON.parse(json)
  end

  def jsonoptions
    @json
  end

  def responses
    DynamicAnnotation::Field.where(field_type: 'task_reference', value: self.id.to_s).to_a.map(&:annotation)
  end

  def response
    @response
  end

  def response=(json)
    params = JSON.parse(json)
    response = Dynamic.new
    response.annotated = self.annotated
    response.annotation_type = params['annotation_type']
    response.set_fields = params['set_fields']
    response.save!
    @response = response
    self.record_timestamps = false
    self.status = 'Resolved'
  end

  private

  def task_options_is_array
    errors.add(:options, 'must be an array') if !self.options.nil? && !self.options.is_a?(Array)
  end

  def set_initial_status
    self.status ||= 'Unresolved'
  end

  def destroy_responses
    self.responses.each do |annotation|
      annotation.load.fields.delete_all
      annotation.delete
    end
  end
end
