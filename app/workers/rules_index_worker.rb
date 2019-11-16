class RulesIndexWorker
  include Sidekiq::Worker

  def perform(team_id)
    begin
      raise 'There is a rules indexing operation in progress for this team already!' if Rails.cache.read("rules_indexing_in_progress_for_team_#{team_id}")
      team = Team.where(id: team_id).last
      return if team.nil? || team.get_rules.blank?
      Rails.cache.write("rules_indexing_in_progress_for_team_#{team.id}", 1)
      index = CheckElasticSearchModel.get_index_alias
      es_body = []
      ProjectMedia.joins(:project).where('projects.team_id' => team.id).find_each do |pm|
        cancel(team_id) and return false if Rails.cache.read("cancel_rules_indexing_for_team_#{team_id}")
        matched_rules_ids = []
        team.apply_rules(pm) do |rules_and_actions|
          matched_rules_ids << Team.rule_id(rules_and_actions)
        end
        es_body << { update: { _index: index, _type: 'media_search', _id: pm.get_es_doc_id, data: { doc: { rules: matched_rules_ids } } } }
      end
      MediaSearch.gateway.client.bulk(body: es_body) unless es_body.empty?
    rescue StandardError => e
      Team.notify_error(e, { team_id: team_id }, RequestStore[:request])
    ensure
      Rails.cache.delete("rules_indexing_in_progress_for_team_#{team_id}")
    end
  end

  def cancel(team_id)
    Rails.cache.delete("rules_indexing_in_progress_for_team_#{team_id}")
    Rails.cache.delete("cancel_rules_indexing_for_team_#{team_id}")
    return true
  end
end
