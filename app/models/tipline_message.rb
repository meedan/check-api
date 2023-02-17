class TiplineMessage < ApplicationRecord
  enum direction: { direction_unset: 0, incoming: 1, outgoing: 2 } # default: direction_unset

  belongs_to :team

  validates_uniqueness_of :external_id
  validates_presence_of :team, :uid, :platform, :language, :direction, :sent_at, :payload
  validates :sent_at, uniqueness: { scope: [:team, :uid, :platform, :language, :direction] }

  class << self
    def from_smooch_payload(msg, payload, event = nil)
      uid = payload.dig('appUser', '_id')
      team = Team.find(Bot::Smooch.config['team_id'])
      general_attributes = {
        uid: uid,
        external_id: msg['_id'],
        team: team,
        event: event,
        language: Bot::Smooch.get_user_language(uid),
        payload: payload.to_json
      }

      trigger_attributes = case payload['trigger']
                            when 'message:appUser'
                              {
                                direction: :incoming,
                                sent_at: parse_timestamp(msg['received']),
                                platform: Bot::Smooch.get_platform_from_message(msg),
                              }
                            when 'message:delivery:channel'
                              {
                                direction: :outgoing,
                                sent_at: parse_timestamp(payload['timestamp']),
                                platform: Bot::Smooch.get_platform_from_payload(payload),
                              }
                            else
                              {}
                            end

      new(general_attributes.merge(trigger_attributes))
    end

    private

    def parse_timestamp(epoch_time)
      begin
        Time.at(epoch_time)
      rescue TypeError => e
        Time.now
      end
    end
  end
end
