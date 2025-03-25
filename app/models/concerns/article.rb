require 'active_support/concern'

module Article
  extend ActiveSupport::Concern

  included do
    include CheckElasticSearch

    belongs_to :user
    belongs_to :author, class_name: 'User', foreign_key: 'author_id', optional: true

    before_validation :set_author, on: :create
    before_validation :set_user
    before_validation :set_channel, on: :create, unless: -> { self.class_name == "ClaimDescription" }
    validates_presence_of :user

    validates :channel, inclusion: { in: %w[imported manual api zapier] }, unless: -> { self.class_name == "ClaimDescription" }
    enum channel: { imported: 0, manual: 1, api: 2, zapier: 3 }

    after_commit :update_elasticsearch_data, :send_to_alegre, :notify_bots, on: [:create, :update]
    after_commit :destroy_elasticsearch_data, on: :destroy
    after_save :create_tag_texts_if_needed
    after_update :schedule_for_permanent_deletion_if_sent_to_trash, if: proc { |obj| obj.is_a?(FactCheck) || obj.is_a?(Explainer) }
  end

  def text_fields
    # Implement it in the child class
  end

  def set_author
    self.author = User.current unless User.current.nil?
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def set_channel
    return if self.channel.present?
    if self.user.is_a?(BotUser) || User.current && User.current.is_a?(BotUser)
      self.channel = "api"
    else
      self.channel = "manual"
    end
  end

  def update_elasticsearch_data
    self.article_elasticsearch_data
  end

  def destroy_elasticsearch_data
    self.article_elasticsearch_data('destroy')
  end

  def article_elasticsearch_data(action = 'create_or_update')
    # Implement it in the child class
  end

  def send_to_alegre
    self.class.delay_for(1.second).send_to_alegre(self.id)
  end

  def notify_bots
    event = {
      'ClaimDescription' => 'save_claim_description',
      'FactCheck' => 'save_fact_check'
    }[self.class.name]
    BotUser.enqueue_event(event, self.project_media.team_id, self) unless self.project_media.nil?
  end

  protected

  def index_in_elasticsearch(pm_id, data)
    pm = ProjectMedia.find_by_id(pm_id)
    unless pm.nil?
      updated_at = Time.now
      pm.update_columns(updated_at: updated_at)
      # Update ES
      data['updated_at'] = updated_at.utc
      pm.update_elasticsearch_doc(data.keys, data, pm.id, true)
    end
  end

  def create_tag_texts_if_needed
    self.class.delay.create_tag_texts_if_needed(self.team_id, self.tags) if self.respond_to?(:tags) && !self.tags.blank?
  end

  def schedule_for_permanent_deletion_if_sent_to_trash
    if self.trashed && !self.trashed_before_last_save
      interval = CheckConfig.get('empty_trash_interval', 30, :integer)
      self.class.delay_for(interval.days, { queue: 'trash', retry: 0 }).delete_permanently(self.id)
    end
  end

  module ClassMethods
    def create_tag_texts_if_needed(team_id, tags)
      tags.to_a.map(&:strip).each do |tag|
        next if TagText.where(text: tag, team_id: team_id).exists?
        tag_text = TagText.new
        tag_text.text = tag
        tag_text.team_id = team_id
        tag_text.skip_check_ability = true
        tag_text.save
      end
    end

    def send_to_alegre(id)
      obj = self.find_by_id(id)
      return if obj.project_media.nil?
      obj.text_fields.each do |field|
        ::Bot::Alegre.send_field_to_similarity_index(obj.project_media, field)
      end unless obj.nil?
    end

    def delete_permanently(id)
      obj = self.find_by_id(id)
      if obj && obj.trashed
        obj.destroy!
        obj.claim_description.destroy! if obj.is_a?(FactCheck)
      end
    end
  end
end
