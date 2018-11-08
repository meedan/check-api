class ProjectSource < ActiveRecord::Base

  attr_accessor :name

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations

  include ProjectAssociation
  include Versioned

  validates_presence_of :source, :project
  validate :source_exists
  validates :source_id, uniqueness: { scope: :project_id }
  before_validation :set_account, on: :create
  after_create :send_slack_notification

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def collaborators
    self.annotators
  end

  def add_extra_elasticsearch_data(ms)
    s = self.source
    unless s.nil?
      ms.associated_type = s.class.name
      ms.title = s.name
      ms.description = s.description
    end
  end

  def slack_params
    user = User.current or self.user
    {
      user: user.nil? ? nil : Bot::Slack.to_slack(user.name),
      user_image: user.nil? ? nil : user.profile_image,
      project: Bot::Slack.to_slack(self.project.title),
      role: user.nil? ? nil : I18n.t("role_" + user.role(self.project.team).to_s),
      team: Bot::Slack.to_slack(self.project.team.name),
      type: I18n.t("activerecord.models.source"),
      title: Bot::Slack.to_slack(self.source.name),
      description: Bot::Slack.to_slack(self.source.description, false),
      url: self.full_url,
      button: I18n.t("slack.fields.view_button", {
        type: I18n.t("activerecord.models.source"), app: CONFIG['app_name']
      })
    }
  end

  def slack_notification_message(update = false)
    params = self.slack_params
    event = update ? "update" : "create"
    no_user = params[:user] ? "" : "_no_user"
    {
      pretext: I18n.t("slack.messages.project_source_#{event}#{no_user}", params),
      title: params[:title],
      title_link: params[:url],
      author_name: params[:user],
      author_icon: params[:user_image],
      text: params[:description],
      fields: [
        {
          title: I18n.t(:'slack.fields.project'),
          value: params[:project],
          short: true
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

  def full_url
    "#{self.project.url}/source/#{self.id}"
  end

  private

  def set_account
    account = self.url.blank? ? nil : Account.create_for_source(self.url, self.source, false, self.disable_es_callbacks)
    unless account.nil?
      errors.add(:base, account.errors.to_a.to_sentence(locale: I18n.locale)) unless account.errors.empty?
      self.source ||= account.source
    end
  end

  def source_exists
    unless self.url.blank?
      a = Account.new
      a.url = self.url
      a.valid?
      account = Account.where(url: a.url).last
      unless account.nil?
        if account.sources.joins(:project_sources).where('project_sources.project_id' => self.project_id).exists?
          errors.add(:base, I18n.t(:duplicate_source))
        end
      end
    end
  end

end
