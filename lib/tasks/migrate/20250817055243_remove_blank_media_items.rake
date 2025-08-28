# rake check:migrate:add_blank_media_to_standalone_fact_checks
namespace :check do
  namespace :migrate do
    task remove_blank_media_items: :environment do
      started = Time.now.to_i
      index_alias = CheckElasticSearchModel.get_index_alias
      client = $repository.client
      # Remove blank iems for unpublished reports
      last_cd_id = Rails.cache.read('check:migrate:remove_unpublished_blank_media_items:claim_description_id') || 0
      ClaimDescription.where("claim_descriptions.id > ?", last_cd_id).joins(:fact_check).joins({project_media: :media})
      .where('medias.type = ?', 'blank')
      .where('fact_checks.report_status = ?', 0)
      .find_in_batches(batch_size: 1000) do |claims|
        print '.'
        # Update project_media_id columns and reset Claims in ES docs
        ids = claims.pluck(:id)
        pm_ids = claims.pluck(:project_media_id)
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
        # Destroy blank medias
        ProjectMedia.where(id: pm_ids).find_in_batches(batch_size: 500) do |pms|
          print '.'
          media_ids = pms.pluck(:media_id)
          Media.where(id: media_ids).destroy_all
          pms.destroy_all
        end
        Rails.cache.write('check:migrate:remove_unpublished_blank_media_items:claim_description_id', ids.max)
      end

      # Replace blank iems with Claim items for published reports
      last_cd_id = Rails.cache.read('check:migrate:remove_published_blank_media_items:claim_description_id') || 0
      ClaimDescription.where("claim_descriptions.id > ?", last_cd_id).joins(:fact_check).joins({project_media: :media})
      .where('medias.type = ?', 'blank')
      .where('fact_checks.report_status = ?', 1)
      .find_in_batches(batch_size: 1000) do |claims|
        print '.'
        # Update project_media_id columns and reset Claims in ES docs
        ids = claims.pluck(:id)
        pm_ids = claims.pluck(:project_media_id)
        ProjectMedia.select('project_medias.*, fact_checks.title AS fc_title')
        .where(id: pm_ids)
        .joins({claim_description: :fact_check})
        .find_in_batches(batch_size: 500) do |items|
          print '.'
          media_ids = items.pluck(:media_id)
          items.each do |pm|
            claim = Claim.create!(quote: pm.fc_title)
            pm.update_column(:media_id, claim.id)
          end
          # Destroy Blank items
          Media.where(id: media_ids).destroy_all
        end
        Rails.cache.write('check:migrate:remove_published_blank_media_items:claim_description_id', ids.max)
      end

      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
    end
  end
end
