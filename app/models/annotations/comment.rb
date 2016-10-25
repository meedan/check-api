class Comment
  include AnnotationBase

  attribute :text, String, presence: true
  validates_presence_of :text

  before_save :extract_check_entities

  notifies_slack on: :save,
                 if: proc { |c| c.should_notify? },
                 message: proc { |c| data = c.annotated.data(c.context); "<#{c.origin}/user/#{c.current_user.id}|*#{c.current_user.name}*> added a note on <#{c.origin}/project/#{c.context_id}/media/#{c.annotated_id}|#{data['title']}>: <#{c.origin}/project/#{c.context_id}/media/#{c.annotated_id}#annotation-#{c.dbid}|\"#{c.text}\">" },
                 channel: proc { |c| c.context.setting(:slack_channel) || c.current_team.setting(:slack_channel) },
                 webhook: proc { |c| c.current_team.setting(:slack_webhook) }

  def content
    { text: self.text }.to_json
  end

  def annotator_callback(value, _mapping_ids = nil)
    user = User.where(email: value).last
    user.nil? ? nil : user
  end

  def target_id_callback(value, mapping_ids)
    mapping_ids[value]
  end

  protected

  def extract_check_urls
    urls = []
    team = self.context_type === 'Project' ? self.context.team : nil
    if team
      words = self.text.to_s.split(/\s+/)
      pattern = Regexp.new(CONFIG['checkdesk_client'])
      words.each do |word|
        match = word.match(pattern)
        if !match.nil? && match[1] == team.subdomain
          urls << word
        end
      end
    end
    urls
  end

  private

  # Supports only media for the time being
  def extract_check_entities
    ids = []
    self.extract_check_urls.each do |url|
      match = url.match(/\/project\/([0-9]+)\/media\/([0-9]+)/)
      unless match.nil?
        pm = ProjectMedia.where(project_id: match[1], media_id: match[2]).last
        ids << pm.id unless pm.nil?
      end
    end
    self.entities = ids
  end
end
