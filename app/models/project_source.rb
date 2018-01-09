class ProjectSource < ActiveRecord::Base

  attr_accessor :name

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations

  include ProjectAssociation
  include Versioned

  validates_presence_of :source_id, :project_id
  validate :source_exists
  validates :source_id, uniqueness: { scope: :project_id }
  before_validation :set_account, on: :create

  after_create :set_elasticsearch_project

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def collaborators
    self.annotators
  end

  def full_url
    "#{self.project.url}/source/#{self.id}"
  end

  def set_elasticsearch_project
    return if self.disable_es_callbacks
    ts = self.source.get_team_source
    unless ts.nil?
      parent = self.get_es_parent_id(ts.id, ts.class.name)
      keys = %w(project_id)
      ids = ProjectSource.where(source_id: self.source_id, project_id: ts.team.projects.map(&:id)).map(&:project_id)
      data = {'project_id' => ids}
      options = {keys: keys, data: data, parent: parent}
      ElasticSearchWorker.perform_in(1.second, YAML::dump(self), YAML::dump(options), 'update_parent')
    end
  end

  private

  def set_account
    account = self.url.blank? ? nil : Account.create_for_source(self.url, self.source, false, self.disable_es_callbacks)
    unless account.nil?
      errors.add(:base, account.errors.to_a.to_sentence(locale: I18n.locale)) unless account.errors.empty?
      self.source ||= account.source
    end
  end

  def source_exists
    unless self.url.blank?
      a = Account.new
      a.url = self.url
      a.valid?
      account = Account.where(url: a.url).last
      unless account.nil?
        if account.sources.joins(:project_sources).where('project_sources.project_id' => self.project_id).exists?
          errors.add(:base, I18n.t(:duplicate_source))
        end
      end
    end
  end

end
