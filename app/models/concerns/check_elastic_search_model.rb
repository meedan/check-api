module CheckElasticSearchModel
  extend ActiveSupport::Concern

  included do
    include ActiveModel::Validations
    include ActiveModel::Validations::Callbacks
    include Elasticsearch::Persistence::Model

    index_name CheckElasticSearchModel.get_index_alias

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
    client = MediaSearch.gateway.client
    index_name = self.get_index_name_prefix
    index_alias = self.get_index_alias
    if client.indices.exists_alias? name: index_alias
      alias_info = client.indices.get_alias name: index_alias
      index_name = alias_info.keys.first
    end
    index_name
  end

  def self.get_index_name_prefix
    CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']
  end

  def self.get_index_alias
     self.get_index_name_prefix + '_alias'
  end

  def self.reindex_es_data
    client = MediaSearch.gateway.client
    source_index = self.get_index_name
    target_index = "#{self.get_index_name_prefix}_#{Time.now.to_i}"
    index_alias = self.get_index_alias
    client.indices.put_alias index: source_index, name: index_alias unless client.indices.exists_alias? name: index_alias
    begin
      # copy data to destination
      MediaSearch.migrate_es_data(source_index, target_index)
      sleep 20
      client.indices.update_aliases body: {
        actions: [
          { remove: { index: source_index, alias: index_alias } },
          { add:    { index: target_index, alias: index_alias } }
        ]
      }
      sleep 1
      MediaSearch.delete_index source_index
    rescue StandardError => e
      Rails.logger.error "[ES Re-Index] Could not start re-indeing : #{e.message}"
    end
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

  module ClassMethods
    def create_index(index_name = nil, c_alias = true)
      index_name = "#{CheckElasticSearchModel.get_index_name_prefix}_#{Time.now.to_i}" if index_name.nil?
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
      client.indices.put_alias index: index_name, name: CheckElasticSearchModel.get_index_alias if c_alias
    end

    def delete_index(index_name = self.index_name)
      client = self.gateway.client
      client.indices.delete index: index_name if client.indices.exists? index: index_name
    end

    def migrate_es_data(source_index, target_index)
      client = self.gateway.client
      MediaSearch.delete_index target_index
      MediaSearch.create_index(target_index, false)
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
