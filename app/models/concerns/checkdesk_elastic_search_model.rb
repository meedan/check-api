module CheckdeskElasticSearchModel
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include Elasticsearch::Persistence::Model

    index_name [Rails.application.engine_name, Rails.env, self.name.parameterize].join('_')

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
    } do 
      mapping do
        indexes :title, type: 'string', analyzer: 'hashtag'
        indexes :description, type: 'string', analyzer: 'hashtag'
        indexes :quote, type: 'string', analyzer: 'hashtag'
        indexes :text, type: 'string', analyzer: 'hashtag'
      end
    end
  end

  def reload
    self.id ? self.class.find(self.id) : self
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
  end
end
