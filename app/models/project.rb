class Project < ActiveRecord::Base

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  belongs_to :user
  belongs_to :team
  has_many :project_sources
  has_many :sources , through: :project_sources
  has_many :project_medias, dependent: :destroy
  has_many :medias , through: :project_medias

  mount_uploader :lead_image, ImageUploader

  before_validation :set_description_and_team_and_user, on: :create

  after_update :update_elasticsearch_data

  validates_presence_of :title
  validates :lead_image, size: true

  has_annotations

  notifies_slack on: :create,
                 if: proc { |p| User.current.present? && p.team.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |p| p.slack_notification_message },
                 channel: proc { |p| p.setting(:slack_channel) || p.team.setting(:slack_channel) },
                 webhook: proc { |p| p.team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'project_created',
                  targets: proc { |p| [p.team] },
                  data: proc { |p| p.to_json }

  include CheckSettings

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def team_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def lead_image_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def avatar
    CONFIG['checkdesk_base_url'] + self.lead_image.url
  end

  def as_json(options = {})
    project = {
      dbid: self.id,
      title: self.title,
      id: Base64.encode64("Project/#{self.id}")
    }
    unless options[:without_team]
      project[:team] = {
        id: Base64.encode64("Team/#{self.id}"),
        dbid: self.team_id,
        projects: { edges: self.team.projects.collect{ |p| { node: p.as_json(without_team: true) } } }
      }
    end
    project
  end

  def medias_count
    self.project_medias.count
  end

  def slack_notifications_enabled=(enabled)
    self.send(:set_slack_notifications_enabled, enabled)
  end

  def slack_channel=(channel)
    self.send(:set_slack_channel, channel)
  end

  def admin_label
    unless self.new_record? || self.team.nil?
      [self.team.name.truncate(15),self.title.truncate(25)].join(' - ')
    end
  end

  def update_elasticsearch_team_bg
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    client = Elasticsearch::Client.new url: url
    options = {
      index: CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index'],
      type: 'media_search',
      body: {
        script: { inline: "ctx._source.team_id=team_id", lang: "groovy", params: { team_id: self.team_id } },
        query: { term: { project_id: { value: self.id } } } }
    }
    client.update_by_query options
  end

  def slack_notification_message
    I18n.t(:slack_create_project,
      user: self.class.to_slack(User.current.name),
      url: self.class.to_slack_url(self.url, "*#{self.title}*")
    )
  end

  def url
    "#{CONFIG['checkdesk_client']}/#{self.team.slug}/project/#{self.id}"
  end

  def export
    self.project_medias.collect{ |pm| Hash[
      project_id: pm.project_id,
      report_id: pm.id,
      report_title: pm.title,
      report_url: pm.url,
      report_date: pm.created_at,
      media_content: pm.media.quote || pm.embed['description'],
      media_url: pm.media.media_url,
      report_status: pm.last_status,
      report_author: pm.user.name,
      tags: pm.get_annotations('tag').to_enum.reverse_each.collect{ |t| t.data['full_tag'] }.reverse.join(', '),
      notes_count: pm.annotations.count,
      notes_ugc_count: pm.get_annotations('comment').count,
      tasks_count: pm.get_annotations('task').count,
      tasks_resolved_count: pm.get_annotations('task').select{ |t| t.status === "Resolved" }.count
    ].merge(
      pm.get_annotations('comment').to_enum.reverse_each.with_index.collect{ |c,i| Hash[
        "note_date_#{i+1}": c.created_at,
        "note_user_#{i+1}": c.annotator.name,
        "note_content_#{i+1}": c.data['text']
      ]}.reduce({}){ |h,o| h.merge(o) }
    ).merge(
      pm.get_annotations('task').map(&:load).to_enum.reverse_each.with_index.collect{ |t,i| r = t.responses.map(&:load).first; Hash[
        "task_question_#{i+1}": t.label,
        "task_user_#{i+1}": r&.annotator&.name,
        "task_date_#{i+1}": r&.created_at,
        "task_answer_#{i+1}": r&.values(['response'], '')&.dig('response'),
        "task_note_#{i+1}": r&.values(['note'], '')&.dig('note'),
       ]}.reduce({}){ |h,o| h.merge(o) }
    )}
  end

  def export_to_csv
    hashes = self.export
    headers = hashes.inject([]) {|res, h| res | h.keys}
    CSV.generate(headers: true) do |csv|
      csv << headers
      hashes.each do |x|
        csv << headers.map {|header| x[header] || ""}
      end
    end
  end

  def csv_filename
    [self.team.slug,self.title.parameterize,DateTime.now].join('_')
  end

  private

  def set_description_and_team_and_user
    self.description ||= ''
    if !User.current.nil? && !self.team_id
      self.team = User.current.current_team
    end
    self.user ||= User.current
  end

  def update_elasticsearch_data
    if self.team_id_changed?
      keys = %w(team_id)
      data = {'team_id' => self.team_id}
      options = {keys: keys, data: data}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_team')
    end
  end

end
