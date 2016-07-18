module PenderData
  def validate_pender_result
    unless self.url.blank?
      result = PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
      self.data = result
      if (result['type'] == 'error')
        errors.add(:base, result['data']['message'])
      else
        # set url with normalized pender URL
        self.url = result['data']['url']
      end
    end
  end
end
