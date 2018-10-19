class Comment < ActiveRecord::Base
  include AnnotationBase
  include HasImage

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

  def content
    { text: self.text }.to_json
  end

  def slack_params
    params = super
    params = params.deep_merge({
      comment: Bot::Slack.to_slack(self.text, false),
      button: I18n.t(:'slack.fields.view_button', {
        type: I18n.t("activerecord.models.#{self.annotated.class_name.underscore}".to_sym), app: CONFIG['app_name']
      })
    })
  end

  def slack_notification_message
    params = self.slack_params
    annotated_type = self.annotated_type === 'Task' ? 'task' : 'media'
    {
      pretext: I18n.t("slack.messages.#{annotated_type}_comment".to_sym, params),
      title: params[:label],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:comment],
      fields: [
        {
          title: I18n.t(:'slack.fields.project'),
          value: params[:project],
          short: true
        },
        {
          title: I18n.t(:'slack.fields.item'),
          value: params[:item],
          short: false
        }
      ],
      actions: [
        {
          type: "button",
          text: params[:button],
          url: params[:url]
        }
      ]
    }
  end

  def file_mandatory?
    false
  end

  protected

  def extract_check_urls
    urls = []
    team = self.annotated_type === 'ProjectMedia' ? self.annotated.project.team : nil
    if team
      words = self.text.to_s.split(/\s+/)
      pattern = Regexp.new(CONFIG['checkdesk_client'])
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
    add_update_nested_obj({op: 'create', nested_key: 'comments', keys: ['text']})
  end

  def update_elasticsearch_comment
    add_update_nested_obj({op: 'update', nested_key: 'comments', keys: ['text']})
  end

  def destroy_elasticsearch_comment
    destroy_es_items('comments')
  end
end
