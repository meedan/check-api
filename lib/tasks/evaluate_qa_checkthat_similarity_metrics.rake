def lookup_text(text, team_id, models)
  conditions = {:text=>text, :models=>models, :fuzzy=>false, :context=>{:has_custom_id=>true, :team_id=>[team_id]}, :match_across_content_types=>true, :threshold=>0.0}
  result = Bot::Alegre.request_api('get', '/text/similarity/', conditions)&.dig('result')
  Hash[result.collect{|x| [x["_source"]["model"], [x["_source"]["context"]["project_media_id"], x["_id"].split("__")[1..-1].join("__")]]}.group_by(&:first).collect{|k,v| [k, v.reject{|x| x.last.last.empty?}.collect(&:last)]}]
end

namespace :check do
  desc "Evaluate metrics for checkthat workspace on QA (usage: bundle exec rake check::evaluate_qa_checkthat_similarity_metrics)"
  task :evaluate_qa_checkthat_similarity_metrics
    team = Team.find_by_slug("checkthat-evaluation")
    user = BotUser.fetch_user
    answer_map = Hash[CSV.read("data/research/CT2022-Task2A-EN-Train_QRELs.tsv", col_sep: "\t").collect{|x| [x[0], x[2]]}]
    evaluation_data = {}
    CSV.read("data/research/CT2022-Task2A-EN-Train-Dev_Queries.tsv", col_sep: "\t")[1..-1].each do |row|
      elasticsearch_results = lookup_text(row.last, team.id, ["elasticsearch"])
      vector_results = lookup_text(row.last, team.id, ["xlm-r-bert-base-nli-stsb-mean-tokens"])
      results=Bot::Alegre.get_merged_similar_items(nil, [{ value: 0.0 }], Bot::Alegre::ALL_TEXT_SIMILARITY_FIELDS, row.last, [team.id])
      id_map = Hash[ProjectMedia.where(id: results.keys).collect{|x| [x.id, x.claim_description.fact_check.title.split(" || ").last].reverse}]
      ordered_ids = results.to_a.sort_by{|k,v| v[:score]}.reverse.collect(&:first)
      merged_data[row.first] = {
        correct_case: answer_map[row.first],
        row: row,
        merged_project_media_ids: ordered_ids,
        merged_index: ordered_ids.index(id_map[answer_map[row.first]]),
        elasticsearch_project_media_ids: elasticsearch_results.values.first.collect(&:first).uniq,
        elasticsearch_index: elasticsearch_results.values.first.collect(&:last).uniq.index(answer_map[row.first]),
        vector_project_media_ids: vector_results.values.first.collect(&:first).uniq,
        vector_index: vector_results.values.first.collect(&:last).uniq.index(answer_map[row.first]),
      }
    end
    f = File.open("merged_checkthat_evaluation_data_#{Time.now.strftime("%Y-%m-%d")}.json", "w")
    f.write(merged_data.to_json)
    f.close
  end
  
  desc "Import claims for checkthat workspace on QA (usage: bundle exec rake check::import_qa_checkthat_similarity_metrics)"
  task :import_qa_checkthat_similarity_metrics do
    require File.expand_path('./config/environment', File.dirname(__FILE__))
    team = Team.find_by_slug("checkthat-evaluation")
    user = BotUser.fetch_user
    User.current = user
    Team.current = team
    #assumes workspace has relevant similarity settings enabled (e.g. vectors are enabled, lanugage is set for language analyzer) as well as active fetch bot integration
    #requires a local folder "vclaims" which is the unzipped result of https://gitlab.com/checkthat_lab/clef2022-checkthat-lab/clef2022-checkthat-lab/-/blob/main/task2/data/subtask-2a--english/vclaims_json.zip
    #also assumes no other fetch writing is happening at the same time in order to establish "inkmarks" on individual items by appending vclaim ID to fact check titles after import
    claim_files = `ls vclaims`.split("\n");false
    claim_data = {}
    claim_files.collect{|file| claim = JSON.parse(File.read("vclaims/#{file}")); claim_data[claim["vclaim_id"]] = claim};false
    claim_files.each do |file|
      puts file
      claim = JSON.parse(File.read("vclaims/#{file}"))
      claim_review = {
        identifier: claim["vclaim_id"],
        author: claim["author"],
        author_link: 'http://example.com',
        claimReviewed: claim['vclaim'],
        headline: claim['title'],
        text: claim['subtitle'],
        service: 'checkthat',
      }
      Bot::Fetch::Import.import_claim_review(JSON.parse(claim_review.to_json), team.id, user.id, 'undetermined', {}, true, false)
      pm = ProjectMedia.where(team_id: team.id, user_id: user.id).last
      fc = pm.claim_description.fact_check
      fc.title= fc.title + " || " + claim["vclaim_id"]
      fc.save!
    end
  end
end
