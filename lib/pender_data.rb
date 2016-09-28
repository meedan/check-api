module PenderData

  def validate_pender_result
    unless self.url.blank?
      result = PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
      if (result['type'] == 'error')
        errors.add(:base, result['data']['message'])
      else
        self.pender_data= result['data']
        # set url with normalized pender URL
        self.url = result['data']['url']
      end
    end
  end

  def set_pender_result_as_annotation
    pender = Bot.where(name: 'Pender').last
    em = Embed.new
    em.embed = self.pender_data
    em.annotated = self
    em.annotator = pender unless pender.nil?
    em.save!
  end

  def pender_data
    @pender_data
  end

  def pender_data=(data)
    @pender_data = data
  end

  def data
    result = Annotation.search query: {
      filtered: {
        query: {
          query_string: {
            query: self.id,
            fields: ["annotated_id"]
          }
          },
          filter: {}
        }
      }
    model = result.last.annotation_type.singularize.camelize.constantize
    em = model.find(result.last.id)
    em.embed
  end

end
