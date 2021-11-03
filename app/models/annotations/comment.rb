class Comment < ApplicationRecord
  include AnnotationBase
  include HasFile
  mount_uploader :file, GenericFileUploader

  field :text
  validates_presence_of :text, if: proc { |comment| comment.file.blank? }

  before_save :extract_check_entities, unless: proc { |p| p.is_being_copied }
  after_commit :send_slack_notification, on: [:create, :update]
  after_commit :add_elasticsearch_comment, on: :create
  after_commit :update_elasticsearch_comment, on: :update
  after_commit :destroy_elasticsearch_comment, on: :destroy

  notifies_pusher on: :destroy,
                  event: 'media_updated',
                  if: proc { |a| a.annotated_type === 'ProjectMedia' && !a.is_being_copied },
                  targets: proc { |a| [a.annotated.media] },
                  data: proc { |a| a.to_json }


  def slack_params
    super.merge({
      comment: Bot::Slack.to_slack(self.text, false),
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.#{self.annotated.class_name.underscore}"), app: CheckConfig.get('app_name')
      })
    })
  end

  def slack_notification_message(_event = nil)
    params = self.slack_params
    pretext = I18n.t("slack.messages.#{self.annotated_type.underscore}_comment", params)
    # Either render a card or add a comment to an existing card
    self.annotated&.should_send_slack_notification_message_for_card? ? self.annotated&.slack_notification_message_for_card(pretext) : nil
  end

  def file_mandatory?
    false
  end

  def content
    data = { text: self.text }
    data.merge!(self.file_data) unless self.file_data.blank?
    data.to_json
  end

  def file_data
    self.file.blank? ? {} : { file: self.public_path }
  end

  protected

  def extract_check_urls
    urls = []
    team = self.annotated_type === 'ProjectMedia' ? self.annotated.team : nil
    if team
      words = self.text.to_s.split(/\s+/)
      pattern = Regexp.new(CheckConfig.get('checkdesk_client'))
      words.each do |word|
        match = word.match(pattern)
        if !match.nil? && Team.slug_from_url(word) == team.slug
          urls << word
        end
      end
    end
    urls
  end

  private

  # Supports only media for the time being
  def extract_check_entities
    ids = []
    self.extract_check_urls.each do |url|
      match = url.match(/\/project\/([0-9]+)\/media\/([0-9]+)/)
      unless match.nil?
        ids << match[2]
      end
    end
    self.entities = ids
  end

  def add_elasticsearch_comment
    add_update_elasticsearch_comment('create')
  end

  def update_elasticsearch_comment
    add_update_elasticsearch_comment('update')
  end

  def add_update_elasticsearch_comment(op)
    # add item/task notes
    if self.annotated_type == 'ProjectMedia'
      add_update_nested_obj({op: op, nested_key: 'comments', keys: ['text']})
    elsif self.annotated_type == 'Task'
      task = self.annotated
      if (task.annotated_type == 'ProjectMedia')
        data = self.data
        data['team_task_id'] = task.team_task_id
        add_update_nested_obj({op: op, obj: task.annotated, nested_key: 'task_comments', keys: ['text', 'team_task_id'], data: data})
      end
    end
  end

  def destroy_elasticsearch_comment
    destroy_es_items('comments') if self.annotated_type == 'ProjectMedia'
    destroy_es_items('task_comments') if self.annotated_type == 'Task'
  end
end
