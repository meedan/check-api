module CheckElasticSearchModel
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include Elasticsearch::Persistence::Model

    index_name CheckElasticSearchModel.get_index_name

    settings analysis: {
      char_filter: {
        space_hashtags_and_arabic: {
          type: 'mapping',
          mappings: [
              "ٱ=>ا",
              "#=>|#"              ]
        }
      },
      filter: {
        hashtag_as_alphanum: {
          type: 'word_delimiter',
          type_table: ['# => ALPHANUM', '@ => ALPHANUM']
        }
      },
      analyzer: {
        check: {
          type: 'custom',
          char_filter: 'space_hashtags_and_arabic',
          tokenizer: 'whitespace',
          filter: ['lowercase', 'hashtag_as_alphanum', 'asciifolding','icu_normalizer','arabic_normalization']
        }
      }
    }

    attribute :annotation_type, String
    before_validation :set_type
  end

  def save!(options = {})
    raise 'Sorry, this is not valid' unless self.save(options)
    self.class.gateway.refresh_index! if CONFIG['elasticsearch_sync']
  end

  def self.get_index_name
    CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']
  end

  def self.reindex_es_data(mapping_keys = nil)
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    client = Elasticsearch::Client.new url: url
    source_index = CheckElasticSearchModel.get_index_name
    target_index = "#{source_index}_reindex"
    # copy data to destination
    migrate_es_data(source_index, target_index)
    sleep 2
    # copy data from destination to original source
    migrate_es_data(target_index, source_index)
    MediaSearch.delete_index target_index
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

  module ClassMethods
    def create_index(index_name = self.index_name)
      client = self.gateway.client
      settings = []
      mappings = []
      [MediaSearch, CommentSearch, TagSearch, DynamicSearch, AccountSearch].each do |klass|
        settings << klass.settings.to_hash
        mappings << klass.mappings.to_hash
      end
      settings = settings.reduce(:merge)
      mappings = mappings.reduce(:merge)
      client.indices.create index: index_name, body: { settings: settings.to_hash, mappings: mappings.to_hash }
    end

    def delete_index(index_name = self.index_name)
      client = self.gateway.client
      if client.indices.exists? index: index_name
        client.indices.delete index: index_name
      end
    end

    def migrate_es_data(source_index, target_index)
      MediaSearch.delete_index target_index
      MediaSearch.create_index target_index
      client.reindex body: { source: { index: source_index }, dest: { index: target_index } }
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
