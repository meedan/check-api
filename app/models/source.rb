class Source < ActiveRecord::Base
  attr_accessor :disable_es_callbacks

  include HasImage
  include CheckElasticSearch

  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  has_many :project_sources
  has_many :account_sources
  has_many :projects, through: :project_sources
  has_many :accounts, through: :account_sources
  belongs_to :user
  belongs_to :team

  has_annotations

  before_validation :set_user, :set_team, on: :create

  validates_presence_of :name

  after_update :update_elasticsearch_source

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def medias
    #TODO: fix me - list valid project media ids
    m_ids = Media.where(account_id: self.account_ids).map(&:id)
    conditions = { media_id: m_ids }
    conditions['projects.team_id'] = Team.current.id unless Team.current.nil?
    ProjectMedia.joins(:project).where(conditions)
  end

  def get_team
    teams = []
    projects = self.projects.map(&:id)
    teams = Project.where(:id => projects).map(&:team_id).uniq unless projects.empty?
    return teams
  end

  def image
    self.avatar || (self.accounts.empty? ? '' : self.accounts.first.data['picture'].to_s)
  end

  def description
    return self.slogan if self.slogan != self.name && !self.slogan.nil?
    self.accounts.empty? ? '' : self.accounts.first.data['description'].to_s
  end

  def collaborators
    self.annotators
  end

  def tags
    self.annotations('tag')
  end

  def comments
    self.annotations('comment')
  end

  def file_mandatory?
    false
  end

  def update_elasticsearch_source
    return if self.disable_es_callbacks
    ps_ids = self.project_sources.map(&:id).to_a
    unless ps_ids.blank?
      parents = ps_ids.map{|id| Base64.encode64("ProjectSource/#{id}") }
      parents.each do |parent|
        self.update_media_search(%w(title description), {'title' => self.name, 'description' => self.description}, parent)
      end
    end
  end

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_team
    self.team = Team.current unless Team.current.nil?
  end
end
