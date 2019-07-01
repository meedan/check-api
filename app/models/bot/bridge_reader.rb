class Bot::BridgeReader < BotUser
  
  check_settings
  
  require 'check_bridge_embed'

  def self.default
    Bot::BridgeReader.new
  end

  def self.notify_embed_system(object, event, item)
    Bot::BridgeReader.default.notify_embed_system(object, event, item)
  end

  def notify_embed_system(object, event, item)
    return if self.disabled? || object.skip_notifications
    url = object.notification_uri(event)
    Check::BridgeEmbed.notify(object.notify_embed_system_payload(event, item), url)
  end

  def disabled?
    CONFIG['bridge_reader_url_private'].blank? || CONFIG['bridge_reader_url'].blank? || CONFIG['bridge_reader_token'].blank?
  end

  DynamicAnnotation::Field.class_eval do
    after_create :notify_created, if: :should_notify?
    after_update :notify_updated, if: :should_notify?
    after_destroy :notify_destroyed, if: :should_notify?

    def notify_embed_system_created_object
      { id: self.annotation.annotated_id.to_s }
    end
    alias notify_embed_system_updated_object notify_embed_system_created_object

    def notify_embed_system_payload(event, object)
      { translation: object, condition: event, timestamp: Time.now.to_i }.to_json
    end

    def notification_uri(_event)
      annotated = self.annotation.annotated
      project = annotated.project
      url = project.nil? ? '' : [CONFIG['bridge_reader_url_private'], 'medias', 'notify', project.team.slug, project.id, annotated.id.to_s].join('/')
      URI.parse(URI.encode(url))
    end

    protected

    def notify_created
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'created', self.notify_embed_system_created_object)
    end

    def notify_updated
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'updated', self.notify_embed_system_updated_object)
    end

    def notify_destroyed
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'destroyed', nil)
    end

    def should_notify?
      self.field_name == 'translation_text' && !Bot::BridgeReader.default.nil? && !self.skip_notifications
    end
  end

  Team.class_eval do
    after_create :notify_created, if: :should_notify?
    after_update :notify_updated, if: :should_notify?

    def notify_embed_system_created_object
      { slug: self.slug }
    end

    def notify_embed_system_updated_object
      self.as_json
    end

    def notify_embed_system_payload(event, object)
      { project: object, condition: event, timestamp: Time.now.to_i, token: CONFIG['bridge_reader_token'] }.to_json
    end

    def notification_uri(event)
      slug = (event == 'created') ? 'check-api' : self.slug
      URI.parse(URI.encode([CONFIG['bridge_reader_url_private'], 'medias', 'notify', slug].join('/')))
    end

    protected

    def notify_created
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'created', self.notify_embed_system_created_object)
    end

    def notify_updated
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'updated', self.notify_embed_system_updated_object)
    end

    def should_notify?
      !Bot::BridgeReader.default.nil? && !self.skip_notifications
    end
  end

  ProjectMedia.class_eval do
    after_destroy :notify_destroyed, if: :should_notify?

    def notify_embed_system_payload(event, object)
      { translation: object, condition: event, timestamp: Time.now.to_i }.to_json
    end

    def notification_uri(_event)
      url = self.project.nil? ? '' : [CONFIG['bridge_reader_url_private'], 'medias', 'notify', self.project.team.slug, self.project.id, self.id.to_s].join('/')
      URI.parse(URI.encode(url))
    end

    protected

    def notify_destroyed
      Bot::BridgeReader.delay_for(1.second).notify_embed_system(self, 'destroyed', nil)
    end

    def should_notify?
      !Bot::BridgeReader.default.nil? && !self.skip_notifications
    end

  end

end
