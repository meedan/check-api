class Source < ActiveRecord::Base
  has_paper_trail on: [:create, :update], if: proc { |_x| User.current.present? }
  has_many :accounts
  has_many :project_sources
  has_many :projects , through: :project_sources
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validates_presence_of :name

  def user_id_callback(value, _mapping_ids = nil)
    user_callback(value)
  end

  def avatar_callback(value, _mapping_ids = nil)
    image_callback(value)
  end

  def medias
    #TODO: fix me - list valid project media ids
    m_ids = Media.where(account_id: self.account_ids).map(&:id)
    ProjectMedia.where(media_id: m_ids)
  end

  def get_team
    teams = []
    projects = self.projects.map(&:id)
    teams = Project.where(:id => projects).map(&:team_id).uniq unless projects.empty?
    return teams
  end

  def image
    self.avatar
  end

  def description
    return self.slogan unless self.slogan == self.name
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

  private

  def set_user
    self.user = User.current unless User.current.nil?
  end

end
