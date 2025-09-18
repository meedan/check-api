class FactCheck < ApplicationRecord
  include Article
  include TagHelpers

  has_paper_trail on: [:create, :update], ignore: [:updated_at, :created_at, :rating, :report_status], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

  enum report_status: { unpublished: 0, published: 1, paused: 2 }

  attr_accessor :skip_report_update, :publish_report, :claim_description_text, :set_original_claim, :skip_create_project_media

  belongs_to :claim_description

  before_validation :set_initial_rating, on: :create, if: proc { |fc| fc.rating.blank? && fc.claim_description.present? }
  before_validation :set_language, on: :create, if: proc { |fc| fc.language.blank? }
  before_validation :set_imported, on: :create
  before_validation :set_claim_description, on: :create, unless: proc { |fc| fc.claim_description.present? }
  before_validation :set_original_claim_for_published_articles, on: :create, if: proc { |fc| fc.publish_report && fc.set_original_claim.blank? }

  validates_presence_of :claim_description
  validates_uniqueness_of :claim_description_id
  validates_format_of :url, with: URI.regexp, allow_blank: true, allow_nil: true
  validate :language_in_allowed_values, :title_or_summary_exists, :rating_in_allowed_values

  before_save :clean_fact_check_tags
  after_save :update_report, unless: proc { |fc| fc.skip_report_update || !DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').exists? || fc.project_media.blank? }
  after_save :update_item_status, if: proc { |fc| fc.saved_change_to_rating? }
  after_create :set_signature_and_project_media, if: proc { |fc| !fc.skip_create_project_media && fc.claim_description.present? && !fc.set_original_claim.blank? }
  after_update :detach_claim_if_trashed

  def text_fields
    ['fact_check_title', 'fact_check_summary']
  end

  def project_media
    self.claim_description&.project_media
  end

  def team_id
    self.claim_description&.team_id
  end

  def team
    self.claim_description&.team
  end

  def update_item_status
    pm = self.project_media
    unless pm.nil?
      s = pm.last_status_obj
      if !s.nil? && s.status != self.rating
        s.skip_check_ability = true
        s.status = self.rating
        s.save!
      end
      # update related items status
      Relationship.delay_for(2.second, { queue: 'smooch' }).replicate_status_to_children(pm.id, User.current&.id, Team.current&.id)
      pm.source_relationships.confirmed.find_each do |r|
        Relationship.delay_for(2.seconds, { queue: 'smooch'}).smooch_send_report(r.id)
      end
    end
  end

  def self.get_exported_data(query, team)
    data = [['ID', 'Title', 'Summary', 'URL', 'Language', 'Report Status', 'Imported?']]
    team.filtered_fact_checks(query).find_each do |fc|
      data << [fc.id, fc.title, fc.summary, fc.url, fc.language, fc.report_status, fc.imported.to_s]
    end
    data
  end

  def clean_fact_check_tags
    return if self.tags.blank?
    self.tags = clean_tags(self.tags)
  end

  def as_tipline_search_result(settings = nil)
    TiplineSearchResult.new(
      id: self.id,
      team: self.team,
      title: self.title,
      body: self.summary,
      language: self.language,
      url: self.url,
      image_url: nil,
      type: :fact_check,
      format: :text,
      link_settings: settings
    )
  end

  private

  def set_language
    languages = self.claim_description&.team&.get_languages || ['en']
    self.language = languages.length == 1 ? languages.first : 'und'
  end

  def set_imported
    self.imported = true if self.user&.type == 'BotUser' # We consider "imported" the fact-checks that are not created by humans inside Check
  end

  def set_claim_description
    # Create ClaimDescription and use `-` in case the value is nil
    claim_description_text = self.claim_description_text || '-'
    cd = ClaimDescription.create!(description: claim_description_text, skip_check_ability: true)
    self.claim_description_id = cd.id
  end

  def set_original_claim_for_published_articles
    self.set_original_claim = self.title
  end

  def language_in_allowed_values
    allowed_languages = self.claim_description&.team&.get_languages || ['en']
    allowed_languages << 'und'
    errors.add(:language, I18n.t(:"errors.messages.invalid_article_language_value")) unless allowed_languages.include?(self.language)
  end

  def rating_in_allowed_values
    unless self.rating.blank? || self.claim_description.nil?
      team = self.claim_description.team
      allowed_statuses = team.verification_statuses('media', nil)['statuses'].collect{ |s| s[:id] }
      errors.add(:rating, I18n.t(:workflow_status_is_not_valid, status: self.rating, valid: allowed_statuses.join(', '))) unless allowed_statuses.include?(self.rating)
    end
  end

  def title_or_summary_exists
    errors.add(:base, I18n.t(:"errors.messages.fact_check_empty_title_and_summary")) if self.title.blank? && self.summary.blank?
  end

  def update_report
    pm = self.project_media
    reports = pm.get_dynamic_annotation('report_design') || Dynamic.new(annotation_type: 'report_design', annotated: pm)
    data = reports.data.to_h.with_indifferent_access
    report = data[:options]
    language = self.language || pm.team.default_language
    report_language = report.to_h.with_indifferent_access[:language]
    default_use_introduction = !!reports.report_design_team_setting_value('use_introduction', language)
    default_introduction = reports.report_design_team_setting_value('introduction', language).to_s
    unless report
      report = {
        language: language,
        use_text_message: true,
        use_introduction: default_use_introduction,
        introduction: default_introduction,
        status_label: pm.status_i18n(pm.last_verification_status, { locale: language }),
        theme_color: pm.last_status_color,
        image: pm.lead_image.to_s
      }
    end
    report.merge!({
      title: self.title.to_s.strip,
      headline: self.title.to_s.strip,
      text: self.summary.to_s.strip,
      description: self.summary.to_s.strip,
      published_article_url: self.url,
      language: self.language
    })
    report.merge!({ use_introduction: default_use_introduction, introduction: default_introduction }) if language != report_language
    data[:options] = report
    unpublished_state = data[:state].blank? ? 'unpublished' : 'paused'
    data[:state] = (self.publish_report ? 'published' : unpublished_state) if data[:state].blank? || !self.publish_report.nil?
    reports.annotator = self.user || User.current
    reports.set_fields = data.to_json
    reports.skip_check_ability = true
    reports.save!
  end

  def article_elasticsearch_data(action = 'create_or_update')
    return if self.project_media.nil? || self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks]
    data = action == 'destroy' ? {
        'fact_check_title' => nil,
        'fact_check_summary' => nil,
        'fact_check_url' => nil,
        'fact_check_languages' => []
      } : {
        'fact_check_title' => self.title,
        'fact_check_summary' => self.summary,
        'fact_check_url' => self.url,
        'fact_check_languages' => [self.language]
      }
    self.index_in_elasticsearch(self.project_media.id, data)
  end

  def set_initial_rating
    pm_rating = self.project_media&.last_status
    default_rating = self.claim_description.team.verification_statuses('media', nil)['default']
    self.rating = pm_rating || default_rating
  end

  def detach_claim_if_trashed
    if self.trashed && !self.trashed_before_last_save
      cd = self.claim_description
      cd.project_media = nil
      cd.save!
    end
  end

  def set_signature_and_project_media
    # set signature
    fc_attr = self.dup.attributes.compact.except("user_id", "claim_description_id", "author_id", "trashed", "report_status")
    self.update_column(:signature, Digest::MD5.hexdigest([fc_attr.to_json, self.team_id].join(':')))
    begin
      self.create_project_media_for_fact_check
    rescue RuntimeError => e
      if e.message.include?("\"code\":#{LapisConstants::ErrorCodes::const_get('DUPLICATED')}") && self.publish_report
        existing_pm = ProjectMedia.find(JSON.parse(e.message)['data']['id'])
        if existing_pm.fact_check.language != self.language
          self.create_project_media_for_fact_check(true)
        else
          raise I18n.t(:factcheck_exists_with_same_language)
        end
      else
        # Skip report update as ProjectMedia creation failed and log the failure
        self.skip_report_update = true
        Rails.logger.info "[FactCheck] Exception when creating ProjectMedia from FactCheck[#{self.id}]: #{e.message}"
        CheckSentry.notify(e, fact_check: self.id, claim_description: self.claim_description.id)
      end
    end
  end

  def create_project_media_for_fact_check(is_duplicate = false)
    pm = ProjectMedia.new
    if is_duplicate
      pm.set_original_claim = self.title
      pm.archived = CheckArchivedFlags::FlagCodes::FACTCHECK_IMPORT
    else
      pm.set_original_claim = self.set_original_claim
    end
    pm.team_id = self.team_id
    pm.claim_description = self.claim_description
    pm.set_status = self.rating
    pm.set_tags = self.tags
    pm.skip_check_ability = true
    pm.save!
    # Set report status
    if self.publish_report
      self.update_report
      self.update_column(:report_status, 'published')
    end
  end
end
