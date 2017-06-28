class ProjectSource < ActiveRecord::Base

  attr_accessor :name, :url

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations
  include Versioned

  validates_presence_of :source_id, :project_id
  before_validation :set_source, :set_account, :set_user, on: :create

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def tags
    self.annotations('tag')
  end

  def comments
    self.annotations('comment')
  end

  def collaborators
    self.annotators
  end

  private

  def set_source
    unless self.name.blank?
      s = self.create_source
      self.source_id = s.id unless s.nil?
    end
  end

  def set_account
    unless self.url.blank?
      self.create_account
    end
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def self.belonged_to_project(psid, pid)
    ps = ProjectSource.find_by_id psid
    if ps && (ps.project_id == pid || ps.versions.where_object(project_id: pid).exists?)
      return ps.id
    else
      ps = ProjectSource.where(project_id: pid, source_id: psid).last
      return ps.id if ps
    end
  end

  protected

  def create_source
    s = Source.new
    s.name = self.name
    s.save!
    s
  end

  def create_account
    a = Account.new
    a.url = self.url
    a.source_id = self.source_id
    a.user = User.current unless User.current.nil?
    a.save!
  end


end
