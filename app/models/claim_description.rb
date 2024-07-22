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
    end
  end
end
