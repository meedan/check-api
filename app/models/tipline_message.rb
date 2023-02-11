class TiplineMessage < ApplicationRecord
  enum direction: { direction_unset: 0, incoming: 1, outgoing: 2 } # default: direction_unset

  belongs_to :team

  validates_uniqueness_of :external_id
  validates_presence_of :team, :uid, :platform, :language, :direction, :sent_at, :payload
  validates :sent_at, uniqueness: { scope: [:team, :uid, :platform, :language, :direction] }

  def self.from_smooch_payload(msg, payload)
    general_attributes = {
      uid: payload.dig('appUser', '_id'),
      external_id: msg['_id'],
      language: Bot::Smooch.get_user_language(msg),
      team_id: Bot::Smooch.config[:team_id],
      payload: payload.to_json
    }

    trigger_attributes = case payload['trigger']
                          when 'message:appUser'
                            {
                              direction: :incoming,
                              sent_at: Time.at(msg['received']),
                              platform: Bot::Smooch.get_platform_from_message(msg),
                            }
                          when 'message:delivery:channel'
                            {
                              direction: :outgoing,
                              sent_at: Time.at(payload['timestamp']),
                              platform: Bot::Smooch.get_platform_from_payload(payload),
                            }
                          else
                            {}
                          end

    new(general_attributes.merge(trigger_attributes))
  end
end
