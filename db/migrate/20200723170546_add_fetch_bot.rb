class AddFetchBot < ActiveRecord::Migration
  def change
    RequestStore.store[:skip_notifications] = true

    meedan_team = Team.where(slug: 'meedan').last || Team.new(name: 'Meedan', slug: 'meedan')
    meedan_team.skip_notifications = true
    meedan_team.skip_clear_cache = true
    meedan_team.skip_check_ability = true
    meedan_team.save!

    Team.current = meedan_team
    tb = BotUser.new
    tb.login = 'fetch'
    tb.name = 'Fetch'
    tb.set_description 'Import fact-checks from an external source.'
    File.open(File.join(Rails.root, 'public', 'fetch.png')) do |f|
      tb.image = f
    end
    tb.set_request_url CONFIG['checkdesk_base_url_private'] + '/api/bots/fetch'
    tb.set_role 'editor'
    tb.set_version '0.0.1'
    tb.set_source_code_url 'https://github.com/meedan/check-api/blob/develop/app/models/bot/fetch.rb'
    tb.set_team_author_id meedan_team.id
    tb.set_events []
    tb.set_settings [
      { name: 'fetch_service_name', label: 'Fetch Service Name', type: 'readonly', default: '' },
      { name: 'status_fallback', label: 'Status Fallback (Check status identifier)', type: 'readonly', default: '' },
      { name: 'status_mapping', label: 'Status Mapping (JSON where key is a reviewRating.ratingValue and value is a Check status identifier)', type: 'readonly', default: '' }
    ]
    tb.set_approved true
    tb.save!

    Team.current = nil
    RequestStore.store[:skip_notifications] = false
  end
end
