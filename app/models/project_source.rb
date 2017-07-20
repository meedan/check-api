class ProjectSource < ActiveRecord::Base

  attr_accessor :name, :url, :disable_es_callbacks

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations

  include ProjectAssociation
  include Versioned

  validates_presence_of :source_id, :project_id
  before_validation :set_account, on: :create

  after_create :add_elasticsearch_data

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

  def get_annotations(type = nil)
    self.annotations.where(annotation_type: type)
  end

  def add_elasticsearch_data
    return if self.disable_es_callbacks
    p = self.project
    s = self.source
    ms = MediaSearch.new
    ms.id = Base64.encode64("ProjectSource/#{self.id}")
    ms.team_id = p.team.id
    ms.project_id = p.id
    ms.set_es_annotated(self)
    ms.title = s.name
    ms.description = s.description
    ms.save!
  end

  private

  def set_account
    unless self.url.blank?
      self.create_account
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
