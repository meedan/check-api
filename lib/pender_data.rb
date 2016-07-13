module PenderData

    def set_pender_metadata
     result =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
     self.data = result
     # set url with normalized pender URL
     self.url = result['data']['url']
    end

    def validate_pender_result
      result =  PenderClient::Request.get_medias(CONFIG['pender_host'], { url: self.url }, CONFIG['pender_key'])
      if (result['type'] == 'error')
        errors.add(:base, result['data']['message'])
      end
    end
end
