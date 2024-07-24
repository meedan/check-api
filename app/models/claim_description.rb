class ClaimDescription < ApplicationRecord
  include Article

  before_validation :set_team, on: :create
  belongs_to :project_media, optional: true
  belongs_to :team
  has_one :fact_check, dependent: :destroy

  accepts_nested_attributes_for :fact_check, reject_if: proc { |attributes| attributes['summary'].blank? }

  validates_presence_of :team
  validates_uniqueness_of :project_media_id, allow_nil: true
  after_commit :update_fact_check, on: [:update]
  after_update :update_report_status
  after_update :replace_media

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
end
