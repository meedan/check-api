class ProjectSource < ActiveRecord::Base

  attr_accessor :name

  belongs_to :project
  belongs_to :source
  belongs_to :user
  has_annotations

  include ProjectAssociation
  include Versioned

  validates_presence_of :source, :project
  validate :source_exists
  validates :source_id, uniqueness: { scope: :project_id }
  before_validation :set_account, on: :create

  def get_team
    p = self.project
    p.nil? ? [] : [p.team_id]
  end

  def collaborators
    self.annotators
  end

  def add_extra_elasticsearch_data(ms)
    s = self.source
    ms.id = Base64.encode64("ProjectSource/#{self.id}")
    ms.associated_type = self.source.class.name
    ms.title = s.name
    ms.description = s.description
  end

  def full_url
    "#{self.project.url}/source/#{self.id}"
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
