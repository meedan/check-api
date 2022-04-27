require 'active_support/concern'

module ClaimAndFactCheck
  extend ActiveSupport::Concern

  included do
    include CheckElasticSearch
    has_paper_trail on: [:create, :update], ignore: [:updated_at, :created_at], if: proc { |_x| User.current.present? }, versions: { class_name: 'Version' }

    belongs_to :user

    before_validation :set_user, on: :create
    after_commit :index_in_elasticsearch, :send_to_alegre, :notify_bots, on: [:create, :update]
  end

  def text_fields
    # Implement it in the child class
  end

  def set_user
    self.user = User.current unless User.current.nil?
  end

  def index_in_elasticsearch
    values = {}
    if self.class.name == 'FactCheck'
      values = { 'fact_check_title' => self.title, 'fact_check_summary' => self.summary }
    else
      values = { 'claim_description_content' => self.description }
    end
    self.update_elasticsearch_doc(self.text_fields, values, self.project_media)
  end

  def send_to_alegre
    self.class.delay_for(1.second).send_to_alegre(self.id)
  end

  def notify_bots
    event = {
      'ClaimDescription' => 'save_claim_description',
      'FactCheck' => 'save_fact_check'
    }[self.class.name]
    BotUser.enqueue_event(event, self.project_media.team_id, self)
  end

  module ClassMethods
    def send_to_alegre(id)
      obj = self.find(id)
      obj.text_fields.each do |field|
        ::Bot::Alegre.send_field_to_similarity_index(obj.project_media, field)
      end
    end
  end
end
