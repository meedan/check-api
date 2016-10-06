class Media < ActiveRecord::Base
  attr_accessible
  attr_accessor :project_id, :duplicated_of

  has_paper_trail on: [:create, :update]
  belongs_to :account
  belongs_to :user
  has_many :project_medias
  has_many :projects, through: :project_medias
  has_annotations

  include PenderData

  validates_presence_of :url
  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create

  before_validation :set_user, on: :create
  after_create :set_pender_result_as_annotation, :set_project, :set_account
  after_rollback :duplicate


  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def account_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  def tags(context = nil)
    self.annotations('tag', context)
  end

  def jsondata(context = nil)
    self.data(context).to_json
  end

  def data(context = nil)
    em_pender = self.annotations('embed').last
    embed = em_pender.embed
    unless context.nil?
      em_u = self.annotations('embed', context)
      em_u.reverse.each do |obj|
        obj.embed.each do |k, v|
          embed[k] = v if embed.has_key?(k)
        end
      end
    end
    embed
  end

  def published
    self.created_at.to_i.to_s
  end

  def get_team
    teams = []
    projects = self.projects.map(&:id)
    projects.empty? ? teams : Project.where(:id => projects).map(&:team_id).uniq
  end

  def associate_to_project
    if !self.project_id.blank? && !ProjectMedia.where(project_id: self.project_id, media_id: self.id).exists?
      pm = ProjectMedia.new
      pm.project_id = self.project_id
      pm.media_id = self.id
      pm.current_user = self.current_user
      pm.context_team = self.context_team
      pm.save!
    end
  end

  def last_status(context = nil)
    last = self.annotations('status', context).first
    last.nil? ? 'Undetermined' : last.status
  end

  def domain
    URI.parse(self.url).host.gsub(/^(www|m)\./, '')
  end

  def project
    Project.find(self.project_id) if self.project_id
  end

  def update_attributes (options = {}, context = nil)
    em = Embed.new
    em.embed = options
    em.annotated = self
    em.annotator = self.current_user unless self.current_user.nil?
    em.context = context unless context.nil?
    em.save!
  end

  private

  def set_user
    self.user = self.current_user unless self.current_user.nil?
  end

  def set_account
    account = Account.new
    account.url = self.pender_data['author_url']
    if account.save
      self.account = account
    else
      self.account = Account.where(url: account.url).last
    end
    self.save!
  end

  def pender_result_is_an_item
    unless self.pender_data.nil?
      errors.add(:base, 'Sorry, this is not a valid media item') unless self.pender_data['type'] == 'item'
    end
  end

  def url_is_unique
    existing = Media.where(url: self.url).first
    self.duplicated_of = existing
    errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
  end

  def set_project
    self.associate_to_project
  end

  def duplicate
    dup = self.duplicated_of
    unless dup.blank?
      dup.project_id = self.project_id
      dup.associate_to_project
      return false
    end
    true
  end
end
