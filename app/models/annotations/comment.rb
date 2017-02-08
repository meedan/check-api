class Comment < ActiveRecord::Base
  include AnnotationBase

  attr_accessible

  field :text
  validates_presence_of :text

  before_save :extract_check_entities
  after_save :add_update_elasticsearch_comment

  notifies_slack on: :save,
                 if: proc { |c| c.should_notify? },
                 message: proc { |c| data = c.annotated.embed; "*#{User.current.name}* added a note on <#{CONFIG['checkdesk_client']}/#{c.annotated.project.team.slug}/project/#{c.annotated.project_id}/media/#{c.annotated_id}|#{data['title']}>\n> #{c.text}" },
                 channel: proc { |c| c.annotated.project.setting(:slack_channel) || c.current_team.setting(:slack_channel) },
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
    team = self.annotated_type === 'ProjectMedia' ? self.annotated.project.team : nil
    if team
      words = self.text.to_s.split(/\s+/)
      pattern = Regexp.new(CONFIG['checkdesk_client'])
      words.each do |word|
        match = word.match(pattern)
        if !match.nil? && Team.slug_from_url(word) == team.slug
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
        ids << match[2]
      end
    end
    self.entities = ids
  end

  def add_update_elasticsearch_comment
    add_update_media_search_child('comment_search', %w(text))
  end

end
