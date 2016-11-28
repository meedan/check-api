module CheckElasticSearchModel
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include Elasticsearch::Persistence::Model

    index_name CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']

    settings analysis: {
      char_filter: {
        space_hashtags: {
          type: 'mapping',
          mappings: ['#=>|#']
        }
      },
      filter: {
        hashtag_as_alphanum: {
          type: 'word_delimiter',
          type_table: ['# => ALPHANUM', '@ => ALPHANUM']
        }
      },
      analyzer: {
        hashtag: {
          type: 'custom',
          char_filter: 'space_hashtags',
          tokenizer: 'whitespace',
          filter: ['lowercase', 'hashtag_as_alphanum']
        }
      }
    }

    attribute :annotation_type, String
    before_validation :set_type
  end

  def reload
    self.id ? self.class.find(self.id) : self
  end

  def save!
    raise 'Sorry, this is not valid' unless self.save
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

  module ClassMethods
    def create_index
      client = self.gateway.client
      index_name = self.index_name
      settings = self.settings.to_hash
      mappings = self.mappings.to_hash
      client.indices.create index: index_name, body: { settings: settings.to_hash, mappings: mappings.to_hash }
    end

    def delete_index
      client = self.gateway.client
      index_name = self.index_name
      if client.indices.exists? index: index_name
        client.indices.delete index: index_name
      end
    end

    def delete_all
      self.delete_index
      self.create_index
      sleep 1
    end

    def all_sorted(order = 'asc', field = 'created_at')
      type = self.name.parameterize
      query = type === 'annotation' ? { match_all: {} } : { bool: { must: [{ match: { annotation_type: type } }] } }
      self.search(query: query, sort: [{ field => { order: order }}, '_score'], size: 10000).results
    end

    def length
      type = self.name.parameterize
      self.count({ query: { bool: { must: [{ match: { annotation_type: type } }] } } })
    end

  end

end
