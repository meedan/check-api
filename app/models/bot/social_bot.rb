module Bot
  module SocialBot
    attr_accessor :translation

    def send_to_social_network_in_background(callback, annotation)
      self.class.delay_for(1.second, retry: 0).send(callback, annotation.id) if !annotation.nil? && annotation.annotation_type == 'translation'
    end

    def send_to_social_network(provider, translation)
      return if translation.nil?
      self.translation = translation

      auth = self.get_auth(provider)
      return if auth.nil?

      return if self.published_to?(provider)

      link = yield
      
      self.store_id(provider, link)
    end

    protected

    def text
      self.translation.get_field_value('translation_text')
    end

    def get_auth(provider)
      publishers = self.translation.annotated.project.get_social_publishing || {}
      publishers[provider]
    end

    def published_to?(provider)
      publishings = DynamicAnnotation::Field.where(annotation_id: self.translation.id, field_name: 'translation_published').to_a
      publishings.select{ |p| JSON.parse(p.value).has_key?(provider.to_s) }.any?
    end

    def store_id(provider, link)
      f = DynamicAnnotation::Field.new
      f.skip_check_ability = true
      f.field_name = 'translation_published'
      f.value = { provider => link }.to_json
      f.annotation_id = self.translation.id
      user = User.current
      User.current = self.translation.annotator
      f.save!
      User.current = user
    end

    def embed_url(visibility = :public, format = :html)
      t = self.translation
      if t && t.annotated && t.annotated.project && t.annotated.project.team
        base_url = CONFIG["bridge_reader_url_#{visibility}"]
        "#{base_url}/medias/embed/#{t.annotated.project.team.slug}/#{t.annotated.project.id}/#{t.annotated.id}.#{format}"
      end
    end
  end
end
