class ProjectMedia < ActiveRecord::Base
  attr_accessible
  attr_accessor :url, :quote, :file, :embed, :disable_es_callbacks

  belongs_to :project
  belongs_to :media
  belongs_to :user
  has_annotations

  validates_presence_of :media_id, :project_id

  before_validation :set_media, :set_user, on: :create
  validate :is_unique, on: :create

  after_create :set_quote_embed, :set_initial_media_status, :add_elasticsearch_data

  notifies_slack on: :create,
                 if: proc { |pm| t = pm.project.team; User.current.present? && t.present? && t.setting(:slack_notifications_enabled).to_i === 1 },
                 message: proc { |pm| pm.slack_notification_message },
                 channel: proc { |pm| p = pm.project; p.setting(:slack_channel) || p.team.setting(:slack_channel) },
                 webhook: proc { |pm| pm.project.team.setting(:slack_webhook) }

  notifies_pusher on: :create,
                  event: 'media_updated',
                  targets: proc { |pm| [pm.project] },
                  data: proc { |pm| pm.media.to_json }

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def media_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def project_id_callback(value, mapping_ids = nil)
    mapping_ids[value]
  end

  def set_initial_media_status
    st = Status.new
    st.annotated = self
    st.annotator = self.user
    st.status = Status.default_id(self.media, self.project)
    st.created_at = self.created_at
    st.disable_es_callbacks = self.disable_es_callbacks
    st.skip_check_ability = true
    st.save!
  end

  def slack_notification_message
    m = self.media
    data = self.embed
    type, text = m.quote.blank? ?
      [ 'link', data['title'] ] :
      [ 'claim', m.quote ]
    "*#{User.current.name}* added a new #{type}: <#{self.origin}/#{self.project.team.slug}/project/#{self.project_id}/media/#{self.id}|*#{text}*>"
  end

  def add_elasticsearch_data
    return if self.disable_es_callbacks
    p = self.project
    m = self.media
    ms = MediaSearch.new
    ms.id = self.id
    ms.team_id = p.team.id
    ms.project_id = p.id
    ms.set_es_annotated(self)
    ms.status = self.last_status
    data = self.embed
    unless data.nil?
      ms.title = data['title']
      ms.description = data['description']
      ms.quote = m.quote
    end
    ms.save!
    #ElasticSearchWorker.perform_in(1.second, YAML::dump(ms), YAML::dump({}), 'add_parent')
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def get_annotations_log
    type = %W(comment tag flag)
    an = self.get_annotations(type).to_a
    # get status
    versions = []
    s = self.get_annotations('status').last
    s = s.load unless s.nil?
    versions = s.versions.to_a unless s.nil?
    if versions.size > 1
      an << s
      versions = versions.drop(2)
      versions.each do |obj|
        an << obj.reify unless obj.reify.nil?
      end
    end
    an.sort_by{|k, _v| k[:updated_at]}.reverse
  end

  def get_media_annotations(type = nil)
    self.media.annotations.where(annotation_type: type).last
  end

  def embed
    em_pender = self.get_media_annotations('embed')
    em_overriden = self.get_annotations('embed').last
    if em_overriden.nil?
      em = em_pender
    else
      em = em_overriden
      em['data']['embed'] = em_pender['data']['embed'] unless em_pender.nil?
    end
    embed = JSON.parse(em.data['embed']) unless em.nil?
    self.overriden_embed_attributes.each{ |k| sk = k.to_s; embed[sk] = em.data[sk] unless em.data[sk].nil? } unless embed.nil?
    embed
  end

  def tags
    self.get_annotations('tag')
  end

  def last_status
    last = self.get_annotations('status').first
    last.nil? ? Status.default_id(self, self.project) : last.data[:status]
  end

  def last_status_obj
    self.get_annotations('status').last
  end

  def published
    self.created_at.to_i.to_s
  end

  def overriden_embed_attributes
    %W(title description username)
  end

  def embed=(info)
    info = info.blank? ? {} : JSON.parse(info)
    unless info.blank?
      em = self.get_annotations('embed').last
      em = em.load unless em.nil?
      em = initiate_embed_annotation(info) if em.nil?
      self.override_embed_data(em, info)
    end
  end

  protected

  def create_image
    m = UploadedImage.new
    m.file = self.file
    m.save!
    m
  end

  def create_claim
    m = Claim.new
    m.quote = self.quote
    m.save!
    m
  end

  def create_link
    m = Link.new
    m.url = self.url
    # call m.valid? to get normalized URL before caling 'find_or_create_by'
    m.valid?
    m = Link.find_or_create_by(url: m.url)
    m
  end

  def create_media
    m = nil
    if !self.file.blank?
      m = self.create_image
    elsif !self.quote.blank?
      m = self.create_claim
    else
      m = self.create_link
    end
    m
  end

  private

  def is_unique
    pm = ProjectMedia.where(project_id: self.project_id, media_id: self.media_id).last
    errors.add(:base, "This media already exists in this project and has id #{pm.id}") unless pm.nil?
  end

  def set_media
    unless self.url.blank? && self.quote.blank? && self.file.blank?
      m = self.create_media
      self.media_id = m.id unless m.nil?
    end
  end

  def set_quote_embed
    self.embed = ({ title: self.media.quote }.to_json) unless self.media.quote.blank?
    self.embed = ({ title: File.basename(self.media.file.path) }.to_json) unless self.media.file.blank?
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  protected

  def initiate_embed_annotation(info)
    em = Embed.new
    em.embed = info.to_json
    em.annotated = self
    em.annotator = User.current unless User.current.nil?
    em
  end

  def override_embed_data(em, info)
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end

end
