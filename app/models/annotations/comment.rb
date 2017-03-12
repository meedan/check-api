class Comment < ActiveRecord::Base
  include AnnotationBase
  include HasImage

  field :text
  validates_presence_of :text, if: proc { |comment| comment.file.blank? }

  before_save :extract_check_entities
  after_save :add_update_elasticsearch_comment
  before_destroy :destroy_elasticsearch_comment

  annotation_notifies_slack :save

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

  def slack_message
    data = self.annotated.embed
    I18n.t(:slack_save_comment,
      user: self.class.to_slack(User.current.name),
      url: self.class.to_slack_url("#{self.annotated_client_url}", "#{data['title']}"),
      comment: self.class.to_slack_quote(self.text),
      project: self.class.to_slack(self.annotated.project.title)
    )
  end

  def file_mandatory?
    false
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

  def destroy_elasticsearch_comment
    destroy_elasticsearch_data(CommentSearch)
  end

end
