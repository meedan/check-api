class Task < ActiveRecord::Base
  include AnnotationBase

  before_validation :set_initial_status, :set_slug, on: :create
  after_create :send_slack_notification, :back_status_to_active
  after_update :send_slack_notification_in_background
  after_destroy :destroy_responses

  field :label
  validates_presence_of :label

  field :type
  def self.task_types
    ['free_text', 'yes_no', 'single_choice', 'multiple_choice', 'geolocation', 'datetime']
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

  field :slug

  field :required, :boolean

  def slack_notification_message
    if self.versions.count > 1
      self.slack_message_on_update
    else
      self.slack_message_on_create
    end
  end

  def slack_message_on_create
    note = self.description.blank? ? '' : I18n.t(:slack_create_task_note, { note: Bot::Slack.to_slack_quote(self.description) })
    assignment = self.assigned_to_id.to_i > 0 ? I18n.t(:slack_create_task_assignment, { assignee: Bot::Slack.to_slack(User.find(self.assigned_to_id).name) }) : ''
    params = self.slack_default_params.merge({
      create_note: note,
      assignment: assignment
    })
    I18n.t(:slack_create_task_message, params)
  end

  def slack_default_params
    {
      user: Bot::Slack.to_slack(User.current.name),
      url: Bot::Slack.to_slack_url(self.annotated_client_url, self.label),
      project: Bot::Slack.to_slack(self.annotated.project.title)
    }
  end

  def slack_message_on_update
    messages = []

    if self.data_changed?
      data = self.data
      data_was = self.data_was

      ['label', 'description'].each do |key|
        if data_was[key].to_s != data[key].to_s
          params = self.slack_default_params.merge({
            from: Bot::Slack.to_slack_quote(data_was[key]),
            to: Bot::Slack.to_slack_quote(data[key])
          })
          messages << I18n.t("slack_update_task_#{key}".to_sym, params)
        end
      end
    end

    messages << self.slack_message_for_assignment if self.assigned_to_id_changed?

    message = messages.join("\n")

    message.blank? ? nil : message
  end

  def slack_message_for_assignment
    action = ''
    uid = nil
    if self.assigned_to_id.to_i > 0
      uid = self.assigned_to_id
      action = 'assign'
    else
      uid = self.assigned_to_id_was
      action = 'unassign'
    end
    params = self.slack_default_params.merge({
      assignee: Bot::Slack.to_slack(User.find(uid).name)
    })
    I18n.t("slack_#{action}_task".to_sym, params)
  end

  def content
    hash = {}
    %w(label type description options status).each{ |key| hash[key] = self.send(key) }
    hash.to_json
  end

  def jsonoptions=(json)
    self.options = JSON.parse(json)
  end

  def jsonoptions
    self.options.to_json
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
    response.disable_es_callbacks = Rails.env.to_s == 'test'
    response.disable_update_status = Rails.env.to_s == 'test'
    response.set_fields = params['set_fields']
    response.save!
    @response = response
    self.record_timestamps = false
    self.status = 'Resolved'
  end

  def first_response
    response = self.responses.first
    response.get_fields.select{ |f| f.field_name =~ /^response/ }.first.to_s unless response.nil?
  end

  def task
    Task.find(self.id)
  end

  def self.send_slack_notification(tid, rid, uid, changes)
    User.current = User.find(uid) if uid > 0
    object = Task.where(id: tid).last
    return if object.nil?
    changes = JSON.parse(changes)
    changes.each do |attribute, change|
      object.send :set_attribute_was, attribute, change[0]
    end
    response = rid > 0 ? Dynamic.find(rid) : nil
    object.instance_variable_set(:@response, response)
    object.send_slack_notification
    User.current = nil
  end

  def self.slug(label)
    label.to_s.parameterize.tr('-', '_')
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

  def set_slug
    self.slug = Task.slug(self.label)
  end

  def send_slack_notification_in_background
    uid = User.current ? User.current.id : 0
    rid = self.response.nil? ? 0 : self.response.id
    Task.delay_for(1.second).send_slack_notification(self.id, rid, uid, self.changes.to_json)
  end

  def back_status_to_active
    return if self.is_being_copied
    if self.required == true && self.annotated_type == 'ProjectMedia'
      annotated = self.annotated
      s = annotated.get_annotations('status').last
      if !s.nil?
        s = s.load
        annotated.set_active_status(s) if Status.completed_ids(annotated.media, annotated.project).include?(s.status)
      end
    end
  end
end
