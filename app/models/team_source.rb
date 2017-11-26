class TeamSource < ActiveRecord::Base
  attr_accessor :disable_es_callbacks

  include CheckElasticSearch

  belongs_to :team
  belongs_to :source
  belongs_to :user

  has_annotations

  before_validation :set_user, on: :create

  validates_presence_of :team_id, :source_id
  validates :source_id, uniqueness: { scope: :team_id }

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
    ms.title = s.get_name
    ms.description = s.description
    ms.save!
  end

  def destroy_elasticsearch_media
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    destroy_elasticsearch_data(MediaSearch, 'parent')
  end

  private

  def set_user
  	self.user = User.current unless User.current.nil?
  end

end
