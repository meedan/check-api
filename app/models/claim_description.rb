class ClaimDescription < ApplicationRecord
  attr_accessor :disable_replace_media

  include Article

  has_paper_trail on: [:create, :update], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  before_validation :set_team, on: :create
  belongs_to :project_media, optional: true
  belongs_to :team
  has_one :fact_check, dependent: :destroy

  accepts_nested_attributes_for :fact_check, reject_if: proc { |attributes| attributes['summary'].blank? }

  validates_presence_of :team
  validates_uniqueness_of :project_media_id, allow_nil: true
  after_commit :update_fact_check, on: [:update]
  after_update :update_report_status
  after_update :replace_media, unless: proc { |cd| cd.disable_replace_media }
  after_update :migrate_claim_and_fact_check_logs, if: proc { |cd| cd.saved_change_to_project_media_id? && !cd.project_media_id.nil? }

  # To avoid GraphQL conflict with name `context`
  alias_attribute :claim_context, :context

  # FIXME: Required by GraphQL API
  def fact_checks
    self.fact_check ? [self.fact_check] : []
  end

  def text_fields
    ['claim_description_content']
  end

  def article_elasticsearch_data(action = 'create_or_update')
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    data = action == 'destroy' ? {
      'claim_description_content' => '',
      'claim_description_context' => ''
    } : {
      'claim_description_content' => self.description,
      'claim_description_context' => self.context
    }
    self.index_in_elasticsearch(data)
  end

  def project_media_was
    ProjectMedia.find_by_id(self.project_media_id_before_last_save)
  end

  def version_metadata(_changes)
    { fact_check: self.fact_check&.title }.to_json
  end

  private

  def set_team
    team = (self.project_media&.team || Team.current)
    self.team = team unless team.nil?
  end

  def update_fact_check
    fact_check = self.fact_check
    if fact_check && self.project_media_id
      fact_check.updated_at = Time.now
      fact_check.save!
      fact_check.update_item_status
    end
  end

  # Pause report when claim/fact-check is removed
  def update_report_status
    if self.project_media_id.nil? && !self.project_media_id_before_last_save.nil?
      # Update report status
      pm = ProjectMedia.find(self.project_media_id_before_last_save)
      report = Annotation.where(annotation_type: 'report_design', annotated_type: 'ProjectMedia', annotated_id: pm.id).last
      unless report.nil?
        report = report.load
        data = report.data.clone.with_indifferent_access
        data[:state] = 'paused'
        report.data = data
        report.save!
      end

      # Update fact-check report status
      fact_check = self.fact_check
      if fact_check
        fact_check.report_status = 'paused'
        fact_check.save!
      end
    end
  end

  # Replace item if fact-check is from a blank media
  def replace_media
    if !self.project_media_id_before_last_save.nil? && ProjectMedia.find_by_id(self.project_media_id_before_last_save)&.type_of_media == 'Blank'
      old_pm = ProjectMedia.find(self.project_media_id_before_last_save)
      new_pm = self.project_media
      old_pm.replace_by(new_pm)
    end
  end

  def migrate_claim_and_fact_check_logs
    # Migrate ClaimDescription logs
    cd_versions = Version.from_partition(self.team_id).where(item_type: 'ClaimDescription', item_id: self.id)
    # Exclude the one related to add/remove based on object_changes field.
    cd_versions = cd_versions.reject do |v|
      oc = begin JSON.parse(v.object_changes) rescue {} end
      oc.length == 1 && oc.keys.include?('project_media_id')
    end
    Version.from_partition(self.team_id).where(id: cd_versions.map(&:id)).update_all(associated_id: self.project_media_id)
    fc_id = self.fact_check&.id
    unless fc_id.nil?
      # Migrate FactCheck logs and exclude create event
      Version.from_partition(self.team_id).where(item_type: 'FactCheck', item_id: fc_id)
      .where.not(event: 'create').update_all(associated_id: self.project_media_id)
    end
  end
end
