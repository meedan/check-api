class TeamSource < ActiveRecord::Base
  attr_accessor :disable_es_callbacks

  include CheckElasticSearch
  include ValidationsHelper

  belongs_to :team
  belongs_to :source
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validates_presence_of :team_id, :source_id
  validates :source_id, uniqueness: { scope: :team_id }
  validate :team_is_not_archived

  after_create :add_elasticsearch_data
  before_destroy :destroy_elasticsearch_media

  def add_elasticsearch_data
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    s = self.source
    ms = MediaSearch.new
    ms.id = Base64.encode64("TeamSource/#{self.id}")
    ms.team_id = self.team_id
    # ms.project_id = p.id
    ms.associated_type = self.source.class.name
    ms.set_es_annotated(self)
    ms.title = s.name
    ms.description = s.description
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

  private

  def set_user
  	self.user = User.current unless User.current.nil?
  end

  def team_is_not_archived
    parent_is_not_archived(self.team, I18n.t(:error_team_archived_for_source, default: "Can't create source under trashed team"))
  end

end
