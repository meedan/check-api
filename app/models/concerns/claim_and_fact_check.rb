require 'active_support/concern'

module ClaimAndFactCheck
  extend ActiveSupport::Concern

  included do
    include CheckElasticSearch

    belongs_to :user

    before_validation :set_user, on: :create
    after_save :index_in_elasticsearch, :send_to_alegre
  end

  def text_fields
    # Implement it in the child class
  end

  def set_user
    self.user ||= User.current
  end

  def index_in_elasticsearch
    self.class.delay_for(1.second).index_in_elasticsearch(self.id)
  end

  def send_to_alegre
    self.class.delay_for(1.second).send_to_alegre(self.id)
  end

  module ClassMethods
    def index_in_elasticsearch(id)
      obj = self.find(id)
      values = {}
      obj.text_fields.each do |field|
        values[field] = obj.project_media.send(field)
      end
      obj.update_elasticsearch_doc(obj.text_fields, values, obj.project_media)
    end

    def send_to_alegre(id)
      obj = self.find(id)
      obj.text_fields.each do |field|
        ::Bot::Alegre.send_field_to_similarity_index(obj.project_media, field)
      end
    end
  end
end
