class FeedRequestError < StandardError
end

class Request < ApplicationRecord
  belongs_to :feed
  belongs_to :media
  belongs_to :similar_to_request, foreign_key: :request_id, class_name: 'Request', optional: true
  has_many :similar_requests, foreign_key: :request_id, class_name: 'Request'
  has_many :project_media_requests
  has_many :project_medias, through: :project_media_requests

  before_validation :set_fields, on: :create
  after_commit :send_to_alegre, on: :create
  after_commit :update_fields, on: :update

  validates_inclusion_of :request_type, in: ['audio', 'video', 'image', 'text']

  cached_field :feed_name,
    start_as: proc { |r| r.feed.name },
    recalculate: proc { |r| r.feed.name },
    update_on: [] # Never changes

  cached_field :media_type,
    start_as: proc { |r| r.media&.type },
    recalculate: proc { |r| r.media&.type },
    update_on: [] # Never changes

  def similarity_threshold
    0.85 # FIXME: Adjust this value for text and image (eventually it can be a feed setting)
  end

  def similarity_model
    ::Bot::Alegre::ELASTICSEARCH_MODEL # FIXME: Use vector models too (eventually it can be a feed setting)
  end

  def attach_to_similar_request!
    media = self.media
    context = { feed_id: self.feed_id }
    threshold = self.similarity_threshold
    # First try to find an identical media
    similar_request_id = Request.where(media_id: media.id, feed_id: self.feed_id).where.not(id: self.id).order('id ASC').first
    if similar_request_id.nil?
      if media.type == 'Claim' && ::Bot::Alegre.get_number_of_words(media.quote) > 1
        params = { text: media.quote, threshold: {::Bot::Alegre::ELASTICSEARCH_MODEL => 0.85, ::Bot::Alegre::MEAN_TOKENS_MODEL =>  0.9}, context: context }
        similar_request_id = ::Bot::Alegre.request_api('get', '/text/similarity/', params)&.dig('result').to_a.collect{ |result| result&.dig('_source', 'context', 'request_id').to_i }.find{ |id| id != 0 && id != self.id }
      elsif ['UploadedImage', 'UploadedAudio', 'UploadedVideo'].include?(media.type)
        type = media.type.gsub(/^Uploaded/, '').downcase
        params = { url: media.file.file.public_url, threshold: threshold, context: context }
        similar_request_id = ::Bot::Alegre.request_api('get', "/#{type}/similarity/", params)&.dig('result').to_a.collect{ |result| result&.dig('context').to_a.collect{ |c| c['request_id'].to_i } }.flatten.find{ |id| id != 0 && id != self.id }
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

  def subscribed
    !self.webhook_url.blank?
  end

  def call_webhook(pm, title, summary, url)
    return unless self.subscribed
    # FIXME: This payload format is specific for one usecase, it should be more generic
    payload = {
      personData: {},
      flowVariables: {
        title: title,
        summary: summary,
        link: url
      }
    }.to_json
    uri = URI(self.webhook_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = uri.scheme == 'https'
    request = Net::HTTP::Post.new("#{uri.path}?#{uri.query}")
    request.body = payload
    request['Content-Type'] = 'application/json'
    self.feed.get_media_headers.to_h.each { |header_name, header_value| request[header_name] = header_value }
    response = http.request(request)
    log = "[Feed Request] Called webhook #{self.webhook_url} for request ##{self.id} and project media ##{pm.id} with title '#{title}', summary '#{summary}' and URL '#{url}', and the response was #{response.code}: '#{response.body}'."
    Rails.logger.info(log)
    Airbrake.notify(FeedRequestError.new(log)) if response.code.to_i >= 400 && Airbrake.configured?
    self.last_called_webhook_at = Time.now
    self.webhook_url = nil
    self.save!
    ProjectMediaRequest.create(project_media_id: pm.id, request_id: self.id, skip_check_ability: true)
  end

  def title
    self.request_type == 'text' ? '' : [self.request_type, self.feed_name, self.media_id].join('-').tr(' ', '-')
  end

  def fact_checked_by(force = false)
    id = self.request_id || self.id
    Rails.cache.fetch("request:#{id}:fact_checked_by", force: force) do
      r = Request.find(id)
      team_names = []

      # Workspaces that published a fact-check / report for any media in that cluster and that is part of the feed
      media_ids = [r.media_id] + r.similar_requests.map(&:media_id)
      team_ids = r.feed.feed_teams.where(shared: true).map(&:team_id)
      pmids = (ProjectMedia.where(media_id: media_ids.uniq, team_id: team_ids).map(&:id) & r.feed.project_media_ids(team_ids.first))
      Annotation.where(annotation_type: 'report_design', annotated_id: pmids).where('data LIKE ?', '%state: published%').each do |published_report|
        team_names << published_report.annotated.team.name
      end

      # Workspaces that returned results for any request in this cluster
      team_names.concat(ProjectMediaRequest.joins(:project_media).where(request_id: r.similar_requests.map(&:id).concat([r.id])).group('project_medias.team_id').count.keys.uniq.collect{ |tid| Team.find(tid).name })

      team_names = team_names.uniq.sort
      r.update_column(:fact_checked_by_count, team_names.size)

      team_names.join(', ')
    end
  end

  def self.update_fact_checked_by(pm)
    request = Request.where(media_id: pm.media_id).first
    request = request&.similar_to_request || request
    request.fact_checked_by(true) unless request.nil?
  end

  def self.get_media_from_query(type, query, fid = nil)
    media = nil
    url = Twitter::TwitterText::Extractor.extract_urls(query)[0]
    if ['audio', 'image', 'video'].include?(type.to_s) && !url.blank?
      media_url = Bot::Smooch.save_locally_and_return_url(url, type, fid)
      open(media_url) do |f|
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
        media = Media.where(type: 'Claim').where('quote ILIKE ?', text).last || Media.create!(type: 'Claim', quote: text)
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
      text = media.quote
      return if text.length < 2
      params = {
        doc_id: doc_id,
        text: text,
        models: [::Bot::Alegre::ELASTICSEARCH_MODEL ,::Bot::Alegre::MEAN_TOKENS_MODEL],
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
    self.subscriptions_count = 1 if self.subscribed
  end

  # When a request is attached to another one, we update some fields of the "parent" request
  def update_fields
    request = self.similar_to_request
    if self.saved_change_to_request_id? && !request.nil?
      request.last_submitted_at = self.created_at
      request.requests_count = request.similar_requests.count + 1
      request.subscriptions_count += 1 if self.subscribed
      request.medias_count = Request.where(request_id: request.id).or(Request.where(id: request.id)).distinct.count(:media_id)
      request.save!
    end
    if self.saved_change_to_webhook_url?
      request ||= self
      request.subscriptions_count -= 1 unless self.subscribed
      request.save!
    end
  end
end
