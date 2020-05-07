namespace :check do
  namespace :migrate do
    task migrate_custom_statuses: :environment do
      client = MediaSearch.gateway.client
      options = {
        index: CheckElasticSearchModel.get_index_alias,
        type: 'media_search',
      }
      statuses = []
      # India Today Group Fact Check team
      statuses << {
        team_slug: 'india-today',
        mapping: {
          'report-false' => 'false', 'report-true' => 'verified', 'report_misleading' => 'misleading',
          'report-inconclusive' => 'inconclusive', 'report_half_true' => 'half_true'}
        }
      # AFP Checamos team
      statuses << {
        team_slug: 'afp-checamos',
        mapping: {
          'report-satira' => 'false', 'checamos' => 'verified', 'report-verdadeiro' => 'true',
          'report-enganoso' => 'misleading', 'report-satira' => 'satire'}
      }
      # AFP Fact Check team
      statuses << {
        team_slug: 'afp-fact-check',
        mapping: { 'report-false' => 'false', 'report-misleading' => 'misleading', 'report-correct' => 'verified' }
      }
      # BOOM team TODO: missing status
      statuses << {
        team_slug: 'boom-factcheck',
        mapping: {
          'in_the_news' => '', 'report-true' => 'verified', 'report-false' => 'false','report-misleading' => 'misleading'}
      }
      # Kweli from Africa Check team
      statuses << {
        team_slug: 'africa-check',
        mapping: {
          'report_false' => 'false', 'report_correct' => 'verified', 'report_misleading' => 'misleading',
          'report_mostly-correct' => 'mostly-correct'}
      }

      statuses.each do |status|
        team = Team.where(slug: status[:team_slug]).last
        next if team.nil?
        status[:mapping].each do |k, v|
        	print "."
          DynamicAnnotation::Field.where(field_name: 'verification_status_status', value: k)
          .joins("INNER JOIN annotations s ON dynamic_annotation_fields.annotation_id = s.id")
          .joins("INNER JOIN project_medias pm ON s.annotated_id = pm.id AND s.annotated_type = 'ProjectMedia'")
          .where('pm.team_id = ?', team.id)
          .find_in_batches(:batch_size => 2500) do |data|
          	print "."
            # update pg
            DynamicAnnotation::Field.where(id: data.map(&:id)).update_all(value: v)
            # TODO: update logs
          end
          # update ES
          body = {
            script: { source: "ctx._source.verification_status = params.status", params: { status: v } },
            query: { term: { verification_status: { value: k } } }
          }
          options[:body] = body
          client.update_by_query options
        end
        # update team status
        team.settings[:media_verification_statuses]["statuses"].delete_if{|s| status[:mapping].keys.include?(s['id']) }
        team.update_columns(settings: team.settings)
      end
    end
  end
end
