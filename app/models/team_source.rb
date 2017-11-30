class TeamSource < ActiveRecord::Base
  attr_accessor :disable_es_callbacks, :identity

  include CheckElasticSearch
  include ValidationsHelper
  include CheckNotifications::Pusher

  belongs_to :team
  belongs_to :source
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validates_presence_of :team_id, :source_id
  validates :source_id, uniqueness: { scope: :team_id }
  validate :team_is_not_archived

  after_create :create_metadata, :add_elasticsearch_data
  before_destroy :destroy_elasticsearch_media

  notifies_pusher on: :update, event: 'source_updated', data: proc { |s| s.to_json }, targets: proc { |s| [s] }

  def image
    file = identity['file']
    return CONFIG['checkdesk_base_url'] + file.url if !file.nil? && file.url != '/images/source.png'
    accounts = self.source.accounts
    file || (accounts.empty? ? CONFIG['checkdesk_base_url'] + '/images/source.png' : accounts.first.data['picture'].to_s)
  end

  def name
    identity['name']
  end

  def description
    slogan = identity['bio']
    return slogan if slogan != identity['name'] && !slogan.nil?
    accounts = self.source.accounts
    accounts.empty? ? '' : accounts.first.data['description'].to_s
  end

  def collaborators
    self.annotators
  end

  def get_versions_log
    PaperTrail::Version.where(associated_type: self.class.name, associated_id: self.id).order('created_at ASC')
  end

  def get_versions_log_count
    self.reload.cached_annotations_count
  end

  def identity=(info)
    info = info.blank? ? {} : JSON.parse(info)
    unless info.blank?
      si = get_annotations('source_identity').last
      si = si.load unless si.nil?
      if si.nil?
        si = SourceIdentity.new
        si.annotated = self
        si.annotator = User.current unless User.current.nil?
      end
      info.each{ |k, v| si.send("#{k}=", v) if si.respond_to?(k) and !v.blank? }
      si.save!
    end
  end

  def identity
    data = {}
    attributes = %W(name bio file)
    si = get_source_annotations('source_identity')
    attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) } unless si.nil?
    si = get_annotations('source_identity').last
    attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) unless si.send(ks).nil? } unless si.nil?
    data
  end

  def medias
    #TODO: fix me - list valid project media ids
    m_ids = Media.where(account_id: self.source.account_ids).map(&:id)
    m_ids.concat ClaimSource.where(source_id: self.source.id).map(&:media_id)
    conditions = { media_id: m_ids }
    conditions['projects.team_id'] = Team.current.id unless Team.current.nil?
    ProjectMedia.joins(:project).where(conditions)
  end

  def refresh_accounts=(refresh)
    return if refresh.blank?
    s = self.source
    s.accounts.each do |a|
      a.refresh_pender_data
      a.save!
    end
    s.update_from_pender_data(s.accounts.first.data)
    s.updated_at = Time.now
    s.save!
  end

  def add_elasticsearch_data
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    ms = MediaSearch.new
    ms.id = Base64.encode64("TeamSource/#{self.id}")
    ms.team_id = self.team_id
    ms.associated_type = self.source.class.name
    ms.set_es_annotated(self)
    ms.title = self.name
    ms.description = self.description
    ms.save!
  end

  def destroy_elasticsearch_media
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    destroy_elasticsearch_data(MediaSearch, 'parent')
  end

  def projects
    p = Project.where(id: self.team.projects).joins(:sources).where('sources.id': self.source_id).last
    p.nil? ? 0 : p.id
  end

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def get_source_annotations(type = nil)
    self.source.annotations.where(annotation_type: type).last
  end

  private

  def set_user
  	self.user = User.current unless User.current.nil?
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived_for_source, default: "Can't create source under trashed team"))
  end

  def create_metadata
    unless DynamicAnnotation::AnnotationType.where(annotation_type: 'metadata').last.nil?
      user = User.current
      User.current = nil
      m = Dynamic.new
      m.skip_check_ability = true
      m.skip_notifications = true
      m.disable_es_callbacks = Rails.env.to_s == 'test'
      m.annotation_type = 'metadata'
      m.annotated = self
      m.annotator = user
      m.set_fields = { metadata_value: {}.to_json }.to_json
      m.save!
      User.current = user
    end
  end

end
