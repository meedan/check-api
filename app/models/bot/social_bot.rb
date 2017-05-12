module Bot
  module SocialBot
    attr_accessor :translation

    def send_to_social_network(provider, translation, &block)
      return if translation.nil?
      self.translation = translation

      auth = self.get_auth(provider)
      return if auth.nil?

      return unless self.published[provider].blank?

      id = yield
      
      self.store_id(provider, id)
    end
    
    protected

    def text
      self.translation.get_field_value('translation_text')
    end

    def get_auth(provider)
      publishers = self.translation.annotated.project.get_social_publishing || {}
      publishers[provider]
    end

    def published
      published = self.translation.get_field_value('translation_published')
      published.blank? ? {} : JSON.parse(published)
    end

    def store_id(provider, id)
      published = self.published
      published[provider] = id

      f = DynamicAnnotation::Field.new
      f.skip_check_ability = true
      f.field_name = 'translation_published'
      f.value = published.to_json
      f.annotation_id = self.translation.id
      f.save!
    end
  end
end
