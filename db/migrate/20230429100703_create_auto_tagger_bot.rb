class CreateAutoTaggerBot < ActiveRecord::Migration[5.2]
  def change
    RequestStore.store[:skip_notifications] = true

    meedan_team = Team.where(slug: 'meedan').last || Team.new(name: 'Meedan', slug: 'meedan')
    meedan_team.skip_notifications = true
    meedan_team.skip_clear_cache = true
    meedan_team.skip_check_ability = true
    meedan_team.save!

    Team.current = meedan_team
    tb = BotUser.new
    tb.login = 'tagger'
    tb.name = 'Tagger'
    tb.set_description 'Add tags to items automatically based on similar items.'
    File.open(File.join(Rails.root, 'public', 'tagger.png')) do |f|
      tb.image = f
    end
    tb.set_role 'editor'
    tb.set_version '0.0.1'
    tb.set_source_code_url 'https://github.com/meedan/check-api/blob/develop/app/models/bot/tagger.rb'
    tb.set_team_author_id meedan_team.id
    tb.set_events [{"event"=>"create_project_media", "graphql"=>"dbid, title, description, type"}]
    tb.set_settings [
      { name: 'auto_tag_prefix', label: 'Emoji prefix', description: 'Emoji to be placed in front of autotags', type: 'string', default: '⚡' },
      { name: 'threshold', label: 'threshold', description: 'Search similarity threshold (0-100)', type: 'integer', default: 70 },
      { name: 'ignore_autotags', label: 'Ingore auto-tags?', description:'If enabled, autotags will not be considered in finding the most common tag', type: 'boolean', default: false },
      { name: 'minimum_count', label: 'Minimum count', description:'Minimum number of times a tag must appear to be applied', type: 'integer', default: 0 }
    ]
    tb.set_approved true
    tb['settings']['listed']=true #Appear on the integrations tab of Check Web
    tb.save!

    Team.current = nil
    RequestStore.store[:skip_notifications] = false
  end
end
