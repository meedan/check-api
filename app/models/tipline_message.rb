class TiplineMessage < ApplicationRecord
  enum direction: { direction_unset: 0, incoming: 1, outgoing: 2 } # default: direction_unset

  belongs_to :team

  validates_presence_of :team, :uid, :platform, :language, :direction, :sent_at, :payload, :state
  validates_inclusion_of :state, in: ['sent', 'received', 'delivered']

  def save_ignoring_duplicate!
    begin
      self.save!
    rescue ActiveRecord::RecordNotUnique
      Rails.logger.info("[Smooch Bot] Not storing tipline message because it already exists. ID: #{self.external_id}. State: #{self.state}.")
    end
  end

  def media_url
    payload = begin JSON.parse(self.payload).to_h rescue self.payload.to_h end
    media_url = nil
    if self.direction == 'incoming'
      media_url = payload.dig('messages', 0, 'mediaUrl')
    elsif self.direction == 'outgoing'
      # WhatsApp Cloud API template
      header = payload.dig('override', 'whatsapp', 'payload', 'interactive', 'header')
      media_url = header[header['type']]['link'] unless header.nil?
      # WhatsApp template on Smooch
      media_url ||= payload.dig('text').to_s.match(/header_image=\[\[([^\]]+)\]\]/).to_a.last
    end
    media_url || payload['mediaUrl']
  end

  class << self
    def from_smooch_payload(msg, payload, event = nil, language = nil)
      msg = msg.with_indifferent_access
      payload = payload.with_indifferent_access

      uid = payload.dig('appUser', '_id')
      team = Team.find(Bot::Smooch.config['team_id'])
      general_attributes = {
        uid: uid,
        external_id: msg['_id'],
        team: team,
        event: event,
        language: language || Bot::Smooch.get_user_language(uid),
        payload: payload
      }

      trigger_attributes = case payload['trigger']
                           when 'message:appUser'
                             {
                               direction: :incoming,
                               state: 'received',
                               sent_at: parse_timestamp(msg['received']),
                               platform: Bot::Smooch.get_platform_from_message(msg),
                             }
                           when 'message:delivery:channel'
                             {
                               direction: :outgoing,
                               state: 'delivered',
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
      rescue TypeError
        Time.now
      end
    end
  end
end
