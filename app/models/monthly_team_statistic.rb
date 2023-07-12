class MonthlyTeamStatistic < ApplicationRecord
  belongs_to :team

  validates_presence_of :start_date, :end_date, :team, :platform, :language
  validates :start_date, uniqueness: { scope: [:platform, :language, :team] }

  include ActionView::Helpers::DateHelper

  # Mapping of attributes to human-readable descriptions
  FIELD_MAPPINGS = {
    id: "ID",
    platform_name: "Platform", # model method
    language: "Language",
    month: "Month", # model method
    average_messages_per_day: 'Average messages per day',
    unique_users: 'Unique users',
    returning_users: 'Returning users',
    valid_new_requests: 'Valid new requests',
    published_native_reports: 'Published native reports',
    published_imported_reports: 'Published imported reports',
    requests_answered_with_report: 'Requests answered with a report',
    reports_sent_to_users: 'Reports sent to users',
    unique_users_who_received_report: 'Unique users who received a report',
    formatted_median_response_time: 'Average (median) response time', # model method
    unique_newsletters_sent: 'Unique newsletters sent',
    new_newsletter_subscriptions: 'New newsletter subscriptions',
    newsletter_cancellations: 'Newsletter cancellations',
    current_subscribers: 'Current subscribers',
    newsletters_delivered: 'Newsletters delivered'
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
