class ReindexAccountInfo < ActiveRecord::Migration
  def change
    url = "http://#{CONFIG['elasticsearch_host']}:#{CONFIG['elasticsearch_port']}"
    client = Elasticsearch::Client.new url: url
    options = {
      index: CONFIG['elasticsearch_index'].blank? ? [Rails.application.engine_name, Rails.env, 'annotations'].join('_') : CONFIG['elasticsearch_index'],
      type: 'media_search'
    }
    Account.all.each do |a|
      # Account info
      data = {}
      em = a.annotations('embed').last
      embed = JSON.parse(em.data['embed']) unless em.nil?
      %W(title description username).each{ |k| sk = k.to_s; data[sk] = embed[sk] unless embed[sk].nil? } unless embed.nil?
      unless data.blank?
        data["id"] = a.id
        pm = []
        a.medias.each{|m| pm = pm + m.project_medias.map(&:id)}
        body = {
          script: { inline: "ctx._source.account=account", lang: "groovy", params: { account: [data] } },
          query: { terms: { _id: pm } }
        }
        client.update_by_query options.merge(body: body)
      end
    end
  end
end
