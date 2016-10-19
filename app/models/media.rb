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

  validate :validate_pender_result, on: :create
  validate :pender_result_is_an_item, on: :create
  validate :url_is_unique, on: :create

  before_validation :set_user, on: :create
  after_create :set_pender_result_as_annotation, :set_project, :set_account
  after_rollback :duplicate


  def current_team
    self.project.team if self.project
  end

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
    # TODO: change the assumption for a one Pender result
    em_pender = self.annotations('embed').last
    embed = JSON.parse(em_pender.embed) unless em_pender.nil?
    # TODO: call annotations with context
    em_u = self.annotations('embed')
    context_id = context.nil? ? nil : context.id
    em_u.reverse.each do |obj|
      if obj.context_id.to_i == context_id.to_i
        ['title', 'description', 'quote'].each do |k|
          embed[k] = obj[k] unless obj[k].nil?
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
      pm.media = self
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
    host = URI.parse(self.url).host
    host.nil? ? nil : host.gsub(/^(www|m)\./, '')
  end

  def project
    Project.find(self.project_id) if self.project_id
  end

  def information=(info)
    info = JSON.parse(info)
    em = Embed.new
    %w(title description quote).each{ |k| em.send("#{k}=", info[k]) unless info[k].blank? }
    em.embed = info.to_json
    em.annotated = self
    em.annotator = self.current_user unless self.current_user.nil?
    em.context = self.project unless self.project.nil?
    em.save!
  end

  private

  def set_user
    self.user = self.current_user unless self.current_user.nil?
  end

  def set_account
    unless self.pender_data.nil?
      account = Account.new
      account.url = self.pender_data['author_url']
      if account.save
        self.account = account
      else
        self.account = Account.where(url: account.url).last
      end
      self.save!
    end
  end

  def pender_result_is_an_item
    unless self.pender_data.nil?
      errors.add(:base, 'Sorry, this is not a valid media item') unless self.pender_data['type'] == 'item'
    end
  end

  def url_is_unique
    unless self.url.nil?
      existing = Media.where(url: self.url).first
      self.duplicated_of = existing
      errors.add(:base, "Media with this URL exists and has id #{existing.id}") unless existing.nil?
    end
  end

  def set_project
    self.associate_to_project
  end

  def duplicate
    dup = self.duplicated_of
    unless dup.blank?
      dup.project_id = self.project_id
      dup.context_team = self.context_team
      dup.current_user = self.current_user
      dup.origin = self.origin
      dup.associate_to_project
      return false
    end
    true
  end
end
