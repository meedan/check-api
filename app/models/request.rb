class Request < ApplicationRecord
  belongs_to :feed
  belongs_to :media
  belongs_to :similar_to_request, foreign_key: :request_id, class_name: 'Request', optional: true
  has_many :similar_requests, foreign_key: :request_id, class_name: 'Request'

  before_validation :set_fields, on: :create
  after_commit :send_to_alegre, on: :create
  after_commit :update_fields, on: :update

  validates_inclusion_of :request_type, in: ['audio', 'video', 'image', 'text']

  def similarity_threshold
    0.85 # FIXME: Adjust this value for text and image (eventually it can be a feed setting)
  end

  def similarity_model
    ::Bot::Alegre::ELASTICSEARCH_MODEL # FIXME: Use vector models too (eventually it can be a feed setting)
  end

  def attach_to_similar_request!
    media = self.media
    similar_request_id = nil
    context = { feed_id: self.feed_id }
    threshold = self.similarity_threshold
    # First try to find an identical media
    similar_request_id = Request.where(media_id: media.id, feed_id: self.feed_id).where.not(id: self.id).order('id ASC').first
    if similar_request_id.nil?
      if media.type == 'Claim' && ::Bot::Alegre.get_number_of_words(media.quote) > 3
        params = { text: media.quote, threshold: threshold, context: context }
        similar_request_id = ::Bot::Alegre.request_api('get', '/text/similarity/', params).dig('result').to_a.collect{ |result| result.dig('_source', 'context', 'request_id').to_i }.find{ |id| id != 0 && id != self.id }
      elsif ['UploadedImage', 'UploadedAudio', 'UploadedVideo'].include?(media.type)
        type = media.type.gsub(/^Uploaded/, '').downcase
        params = { url: media.file.file.public_url, threshold: threshold, context: context }
        similar_request_id = ::Bot::Alegre.request_api('get', "/#{type}/similarity/", params).dig('result').to_a.collect{ |result| result.dig('context').to_a.collect{ |c| c['request_id'].to_i } }.flatten.find{ |id| id != 0 && id != self.id }
      end
    end
    unless similar_request_id.blank?
      similar_request = Request.where(id: similar_request_id, feed_id: self.feed_id).last
      self.similar_to_request = similar_request&.similar_to_request || similar_request
      self.save!
    end
  end

  def medias
    Media.distinct.joins(:requests).where('requests.request_id = ? OR medias.id = ?', self.id, self.media_id)
  end

  def self.get_media_from_query(type, query)
    media = nil
    url = Twitter::TwitterText::Extractor.extract_urls(query)[0]
    if ['audio', 'image', 'video'].include?(type.to_s) && !url.blank?
      open(url) do |f|
        data = f.read
        hash = Digest::MD5.hexdigest(data)
        extension = { audio: 'mp3', image: 'jpeg', video: 'mp4' }[type.to_sym]
        filename = "#{hash}.#{extension}"
        filepath = File.join(Rails.root, 'tmp', filename)
        media_type = "Uploaded#{type.camelize}"
        File.atomic_write(filepath) { |file| file.write(data) }
        media = Media.where(type: media_type, file: filename).last
        if media.nil?
          media = Media.new(type: media_type)
          File.open(filepath) do |f2|
            media.file = f2
            media.save!
          end
        end
        FileUtils.rm_f filepath
      end
    else
      if url.blank?
        text = ::Bot::Smooch.extract_claim(query)
        media = Media.where(type: 'Claim', quote: text).last || Media.create!(type: 'Claim', quote: text)
      else
        link = ::Bot::Smooch.extract_url(url) # Parse URL to get a normalized/canonical one
        url = (link ? link.url : url)
        media = Media.where(type: 'Link', url: url).last || Media.create!(type: 'Link', url: url)
      end
    end
    media
  end

  def self.send_to_alegre(id)
    request = self.find_by_id(id)
    media = request.media
    doc_id = Base64.encode64(['check', 'request', request.id, 'media'].join('-')).strip.delete("\n").delete('=')
    context = {
      has_custom_id: true,
      feed_id: request.feed_id,
      request_id: request.id
    }
    if media.type == 'Claim'
      params = {
        doc_id: doc_id,
        text: media.quote,
        model: request.similarity_model,
        context: context
      }
      ::Bot::Alegre.request_api('post', '/text/similarity/', params)
    elsif ['UploadedImage', 'UploadedAudio', 'UploadedVideo'].include?(media.type)
      type = media.type.gsub(/^Uploaded/, '').downcase
      url = media.file&.file&.public_url
      params = {
        doc_id: doc_id,
        url: url,
        context: context,
        match_across_content_types: true,
      }
      ::Bot::Alegre.request_api('post', "/#{type}/similarity/", params)
    end
  end

  private

  def send_to_alegre
    self.class.delay_for(1.second).send_to_alegre(self.id)
  end

  def set_fields
    self.last_submitted_at = Time.now
    self.medias_count = 1
    self.requests_count = 1
  end

  # When a request is attached to another one, we update some fields of the "parent" request
  def update_fields
    request = self.similar_to_request
    if self.saved_change_to_request_id? && !request.nil?
      request.last_submitted_at = self.created_at
      request.requests_count = request.similar_requests.count + 1
      request.medias_count = Request.where(request_id: request.id).or(Request.where(id: request.id)).distinct.count(:media_id)
      request.save!
    end
  end
end
