class MonthlyTeamStatistic < ApplicationRecord
  belongs_to :team

  validates_presence_of :start_date, :end_date, :team, :platform, :language
  validates :start_date, uniqueness: { scope: [:platform, :language, :team] }

  include ActionView::Helpers::DateHelper

  # Mapping of attributes to human-readable descriptions
  FIELD_MAPPINGS = {
    id: 'ID',
    platform_name: 'Platform', # model method
    language: 'Language',
    month: 'Month', # model method
    whatsapp_conversations: 'WhatsApp conversations',
    whatsapp_conversations_business: 'WhatsApp marketing conversations (business-initiated)',
    whatsapp_conversations_user: 'WhatsApp service conversations (user-initiated)',
    unique_users: 'Unique users',
    returning_users: 'Returning users',
    published_reports: 'Published reports',
    positive_searches: 'Positive searches',
    negative_searches: 'Negative searches',
    reports_sent_to_users: 'Reports sent to users',
    unique_users_who_received_report: 'Unique users who received a report',
    formatted_median_response_time: 'Average (median) response time', # model method
    current_subscribers: 'Current subscribers',
    unique_newsletters_sent: 'Unique newsletters sent',
    newsletters_sent: 'Total newsletters sent',
    newsletters_delivered: 'Total newsletters delivered',
    new_newsletter_subscriptions: 'Newsletter subscriptions',
    newsletter_cancellations: 'Newsletter cancellations'
  }.freeze

  def formatted_hash
    {}.tap do |formatted_hash|
      FIELD_MAPPINGS.each do |attribute_name, human_readable_label|
        formatted_hash[human_readable_label] = public_send(attribute_name.to_sym) || '-'
      end
    end
  end

  # Below methods must match a key in FIELD_MAPPINGS to be included in
  # the .formatted_hash output
  def month
    start_date&.strftime('%b %Y')
  end

  def formatted_median_response_time
    distance_of_time_in_words(median_response_time) if median_response_time
  end

  def platform_name
    Bot::Smooch::SUPPORTED_INTEGRATION_NAMES[platform]
  end
end
