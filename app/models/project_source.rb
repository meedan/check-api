class ProjectSource < ActiveRecord::Base

  attr_accessor :name, :url

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations

  include ProjectAssociation
  include Versioned

  validates_presence_of :source_id, :project_id
  before_validation :set_account, on: :create

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
    a.source_id = self.source_id unless self.source_id.blank?
    a.user = User.current unless User.current.nil?
    a.save!
    # Set source if name is blank
    self.source_id = a.reload.source_id if self.source_id.blank?
  end


end
