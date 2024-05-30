require 'active_support/concern'

module Article
  extend ActiveSupport::Concern

  included do
    include CheckElasticSearch

    has_paper_trail on: [:create, :update], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

    belongs_to :user

    before_validation :set_user
    validates_presence_of :user

    after_commit :update_elasticsearch_data, :notify_bots, on: [:create, :update] #:send_to_alegre, 
    after_commit :destroy_elasticsearch_data, on: :destroy
  end

  def text_fields
    # Implement it in the child class
  end

  def set_user
    self.user = User.current unless User.current.nil?
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
    # self.class.delay_for(1.second).send_to_alegre(self.id)
  end

  def notify_bots
    event = {
      'ClaimDescription' => 'save_claim_description',
      'FactCheck' => 'save_fact_check'
    }[self.class.name]
    BotUser.enqueue_event(event, self.project_media.team_id, self)
  end

  protected

  def index_in_elasticsearch(data)
    # touch project media to update `updated_at` date
    pm = self.project_media
    pm = ProjectMedia.find_by_id(pm.id)
    unless pm.nil?
      updated_at = Time.now
      pm.update_columns(updated_at: updated_at)
      # Update ES
      data['updated_at'] = updated_at.utc
      pm.update_elasticsearch_doc(data.keys, data, pm.id, true)
    end
  end

  module ClassMethods
    def send_to_alegre(id)
      obj = self.find_by_id(id)
      obj.text_fields.each do |field|
        ::Bot::Alegre.send_field_to_similarity_index(obj.project_media, field)
      end unless obj.nil?
    end
  end
end
