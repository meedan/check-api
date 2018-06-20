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
    CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index']
  end

  def self.get_index_alias
     self.get_index_name + '_alias'
  end

  def self.reindex_es_data
    client = MediaSearch.gateway.client
    source_index = CheckElasticSearchModel.get_index_name
    target_index = "#{source_index}_#{Time.now.to_i}"
    index_alias = CheckElasticSearchModel.get_index_alias
    if client.indices.exists_alias? name: index_alias
      alias_info = client.indices.get_alias name: index_alias
      source_index = alias_info.keys.first
    else
      client.indices.put_alias index: source_index, name: index_alias
    end
      # copy data to destination
    MediaSearch.migrate_es_data(source_index, target_index)
    client.indices.update_aliases body: {
      actions: [
        { remove: { index: source_index, alias: index_alias } },
        { add:    { index: target_index, alias: index_alias } }
      ]
    }
    MediaSearch.delete_index source_index
  end

  private

  def set_type
    self.annotation_type ||= self.class.name.parameterize
  end

  module ClassMethods
    def create_index(index_name = nil)
      index_name = "#{CheckElasticSearchModel.get_index_name}_#{Time.now.to_i}" if index_name.nil?
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
      client.indices.put_alias index: index_name, name: CheckElasticSearchModel.get_index_alias
    end

    def delete_index(index_name = self.index_name)
      client = self.gateway.client
      if client.indices.exists? index: index_name
        client.indices.delete index: index_name
      end
      # index_alias = "#{self.index_name}"
      # if client.indices.exists_alias? name: index_alias
      #   client.indices.delete_alias index: '*', name: index_alias
      # end
    end

    def migrate_es_data(source_index, target_index)
      client = self.gateway.client
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
