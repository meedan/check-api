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
          'checamos' => 'verified', 'report-verdadeiro' => 'true', 'report-enganoso' => 'misleading',
          'report-satira' => 'satire', 'report-falso' => 'false'}
      }
      # AFP Fact Check team
      statuses << {
        team_slug: 'afp-fact-check',
        mapping: { 'report-false' => 'false', 'report-misleading' => 'misleading', 'report-correct' => 'verified' }
      }
      # BOOM team
      statuses << {
        team_slug: 'boom-factcheck',
        mapping: { 'report-true' => 'verified', 'report-false' => 'false','report-misleading' => 'misleading'}
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
          s_values = [k, k + '\n...'].map(&:to_yaml).map{|m| m.gsub("\\n", "\n")}
          DynamicAnnotation::Field.select("dynamic_annotation_fields.id AS id, pm.id AS pm_id").where("field_name = ? AND value IN (?)", 'verification_status_status', s_values)
          .joins("INNER JOIN annotations s ON dynamic_annotation_fields.annotation_id = s.id")
          .joins("INNER JOIN project_medias pm ON s.annotated_id = pm.id AND s.annotated_type = 'ProjectMedia'")
          .where('pm.team_id = ?', team.id)
          .find_in_batches(:batch_size => 2500) do |data|
            print "."
            ids = data.map(&:id)
            # update pg
            DynamicAnnotation::Field.where(id: ids).update_all(value: v)
            # remove log entry related to removed status
            s_versions = s_values.map{|m| m.gsub("\n", "\\n")}
            s_versions.each do |s_version|
              Version.from_partition(team.id).where(item_type: 'DynamicAnnotation::Field', item_id: ids)
              .where_object_changes(value: s_version).delete_all
            end
            # update status cache
            data.map(&:pm_id).each{|pm| Rails.cache.write("check_cached_field:ProjectMedia:#{pm}:status", v)}
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
