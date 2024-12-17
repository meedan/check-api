namespace :check do
  namespace :migrate do
    task set_language_for_explainers: :environment do
      started = Time.now.to_i
      query = Explainer.where(language: nil)
      n = query.count
      i = 0
      query.find_each do |explainer|
        i += 1
        language = explainer.team&.get_language || 'und'
        explainer.update_column(:language, language)
        puts "[#{Time.now}] [#{i}/#{n}] Setting language for explainer ##{explainer.id} as #{language}"
      end
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes. Number of explainers without language: #{query.count}"
    end
  end
end
