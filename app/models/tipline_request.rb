class TiplineRequest < ApplicationRecord
  include CheckElasticSearch

  belongs_to :associated, polymorphic: true
  belongs_to :project_media, -> { where(tipline_requests: { associated_type: 'ProjectMedia' }) }, foreign_key: 'associated_id', optional: true
  belongs_to :user, optional: true

  before_validation :set_team_and_user, :set_smooch_data_fields, on: :create

  validates_presence_of :smooch_request_type, :language, :platform
  validate :platform_allowed_values

  def self.request_types
    %w(default_requests timeout_requests relevant_search_result_requests resource_requests irrelevant_search_result_requests timeout_search_requests menu_options_requests)
  end
  validates_inclusion_of :smooch_request_type, in: TiplineRequest.request_types

  after_commit :add_elasticsearch_field, on: :create
  after_commit :update_elasticsearch_field, on: :update
  after_commit :destroy_elasticsearch_field, on: :destroy

  scope :no_articles_sent, ->(project_media_id) {
    where(associated_type: 'ProjectMedia', associated_id: project_media_id, smooch_report_received_at: 0,
      smooch_report_update_received_at: 0, smooch_report_sent_at: 0, smooch_report_correction_sent_at: 0
    ).where.not(smooch_request_type: %w(relevant_search_result_requests irrelevant_search_result_requests timeout_search_requests))
  }

  def returned_search_results?
    self.smooch_request_type =~ /search/
  end

  def responded_at
    report_sent_at = [self.smooch_report_received_at, self.smooch_report_update_received_at, self.smooch_report_sent_at, self.smooch_report_correction_sent_at].map(&:to_i).select{ |timestamp| timestamp > 0 }.min
    self.returned_search_results? ? self.created_at.to_i : report_sent_at.to_i
  end

  def smooch_user_slack_channel_url
    return if self.smooch_data.blank?
    slack_channel_url = ''
    data = self.smooch_data
    unless data.nil?
      key = "SmoochUserSlackChannelUrl:Team:#{self.team_id}:#{data['authorId']}"
      slack_channel_url = Rails.cache.read(key)
      if slack_channel_url.blank?
        obj = self.associated
        slack_channel_url = get_slack_channel_url(obj, data)
        Rails.cache.write(key, slack_channel_url) unless slack_channel_url.blank?
      end
    end
    slack_channel_url
  end

  def smooch_user_external_identifier
    return if self.tipline_user_uid.blank?
    Rails.cache.fetch("smooch:user:external_identifier:#{self.tipline_user_uid}") do
      field = DynamicAnnotation::Field.where('field_name = ? AND dynamic_annotation_fields_value(field_name, value) = ?', 'smooch_user_id', self.tipline_user_uid.to_json).last
      return '' if field.nil?
      smooch_user_data = JSON.parse(field.annotation.load.get_field_value('smooch_user_data')).with_indifferent_access
      user = smooch_user_data&.dig('raw', 'clients', 0) || {}
      case user[:platform]
      when 'whatsapp'
        user[:displayName]
      when 'telegram', 'instagram'
        '@' + user[:raw][:username].to_s
      when 'messenger', 'viber', 'line'
        user[:externalId]
      when 'twitter'
        '@' + user[:raw][:screen_name]
      else
        ''
      end
    end
  end

  def smooch_user_request_language
    self.language.to_s
  end

  def associated_graphql_id
    Base64.encode64("#{self.associated_type}/#{self.associated_id}")
  end

  def hit_nested_objects_limit?
    associated = self.associated
    associated.tipline_requests.count > CheckConfig.get('nested_objects_limit', 10000, :integer)
  end

  private

  def set_team_and_user
    self.team_id ||= Team.current&.id
    self.user_id ||= User.current&.id
  end

  def set_smooch_data_fields
    unless self.smooch_data.blank?
      # Avoid PG::UntranslatableCharacter exception
      value = self.smooch_data.to_json.gsub('\u0000', '')
      self.smooch_data = JSON.parse(value)
      self.tipline_user_uid ||= self.smooch_data.dig('authorId')
      self.language ||= self.smooch_data.dig('language')
      self.platform ||= self.smooch_data.dig('source', 'type')
    end
  end

  def platform_allowed_values
    allowed_types = Bot::Smooch::SUPPORTED_INTEGRATIONS
    unless allowed_types.include?(self.platform)
      errors.add(:platform, I18n.t('errors.messages.platform_allowed_values_error', **{ type: self.platform, allowed_types: allowed_types.join(', ') }))
    end
  end

  def get_slack_channel_url(obj, data)
    slack_channel_url = nil
    tid = obj.team_id
    smooch_user_data = DynamicAnnotation::Field.where(field_name: 'smooch_user_id', annotation_type: 'smooch_user')
    .where('dynamic_annotation_fields_value(field_name, value) = ?', data['authorId'].to_json)
    .joins("INNER JOIN annotations a ON a.id = dynamic_annotation_fields.annotation_id")
    .where("a.annotated_type = ? AND a.annotated_id = ?", 'Team', tid).last
    unless smooch_user_data.nil?
      field_value = DynamicAnnotation::Field.where(field_name: 'smooch_user_slack_channel_url', annotation_type: 'smooch_user', annotation_id: smooch_user_data.annotation_id).last
      slack_channel_url = field_value.value unless field_value.nil?
    end
    slack_channel_url
  end

  def add_elasticsearch_field
    index_field_elastic_search('create')
  end

  def update_elasticsearch_field
    index_field_elastic_search('update')
  end

  def destroy_elasticsearch_field
    index_field_elastic_search('destroy')
  end

  protected

  def index_field_elastic_search(op)
    return if self.disable_es_callbacks || RequestStore.store[:disable_es_callbacks] || self.associated_type != 'ProjectMedia'
    obj = self.associated
    unless obj.nil?
      if op == 'destroy'
        destroy_es_items('requests', 'destroy_doc_nested', obj.id)
      else
        identifier = begin self.smooch_user_external_identifier&.value rescue self.smooch_user_external_identifier end
        data = {
          'username' => self.smooch_data['name'],
          'identifier' => identifier&.gsub(/[[:space:]|-]/, ''),
          'content' => self.smooch_data['text'],
          'language' => self.language,
        }
        options = { op: op, pm_id: obj.id, nested_key: 'requests', keys: data.keys, data: data, skip_get_data: true }
        self.add_update_nested_obj(options)
      end
    end
  end
end
