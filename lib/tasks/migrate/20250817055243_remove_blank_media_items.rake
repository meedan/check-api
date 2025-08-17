# rake check:migrate:add_blank_media_to_standalone_fact_checks
namespace :check do
  namespace :migrate do
    task remove_blank_media_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      last_cd_id = Rails.cache.read('check:migrate:remove_blank_media_items:claim_description_id') || 0
      ClaimDescription.where("id > ?", last_cd_id).joins({project_media: :media}).where('medias.type = ?', 'blank')
      .find_in_batches(batch_size: 1000) do |claims|
        print '.'
        # Update project_media_id columns and reset Claims in ES docs
        ids = claims.pluck(:id)
        ClaimDescription.update_all(project_media_id: nil)
        body = {
          script: { 
            source: "
              ctx._source.claim_description_content = params.content; \
              ctx._source.claim_description_context = params.context; \
              ctx._source.fact_check_title= params.fc_title; \
              ctx._source.fact_check_summary = params.fc_summary; \
              ctx._source.fact_check_url= params.fc_url; \
              ctx._source.fact_check_languages= params.fc_languages \
            ",
            params: { 
              content: nil,
              context: nil,
              fc_title: nil,
              fc_summary: nil,
              fc_url: nil,
              fc_languages: []
            }
          },
          query: { terms: { annotated_id: ids } }
        }
        options[:body] = body
        client.update_by_query options
        Rails.cache.write('check:migrate:remove_blank_media_items:claim_description_id', ids.max)
      end
      # Destroy blank medias
      ProjectMedia.joins(:media).where("medias.type = ?", 'blank').find_in_batches(batch_size: 1000) do |pms|
        print '.'
        media_ids = pms.pluck(:media_id)
        Media.where(id: media_ids).destroy_all
        pms.destroy_all
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Number of standalone fact-checks without blank media: #{query.count}"
    end
  end
end
