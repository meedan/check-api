require 'sample_data'

class TestController < ApplicationController
  before_action :check_environment, :init_bot_events
  after_action :trigger_bot_events

  include SampleData

  def confirm_user
    user = User.where(email: params[:email]).last
    unless user.nil?
      user.skip_check_ability = true
      user.confirm
    end
    render plain: 'OK'
  end

  def make_team_public
    team = Team.where(slug: params[:slug]).last
    unless team.nil?
      team.private = false
      team.save!
    end
    render plain: 'OK'
  end

  def install_bot
    team = Team.where(slug: params[:slug]).last
    login = params[:bot]
    settings = begin JSON.parse(params[:settings]) rescue params[:settings].to_h end
    bot = BotUser.find_by_login(login) || BotUser.create!(login: login, name: login.capitalize, settings: { approved: true })
    team_user = bot.install_to!(team)
    team_user = TeamUser.find(team_user.id)
    team_user.settings = team_user.settings.merge(settings)
    team_user.save!
    render_success 'team', team.reload
  end

  def new_user
    u = create_user params
    u.accept_terms = true
    render_success 'user', u
  end

  def create_team_project_and_two_users
    t = create_team
    u1 = create_user
    u2 = create_user
    u1.accept_terms = true
    u2.accept_terms = true
    create_team_user team: t, user: u1, role: 'admin'
    create_team_user team: t, user: u2, role: 'collaborator'
    pr = create_project team: t, current_user: u1
    ret = {:team =>t, :user1 => u1, :user2 => u2, :project => pr}

    render_success 'team_users', ret
  end

  def add_team_user
    team = Team.where(slug: params[:slug]).last
    user = User.where(email: params[:email]).last
    role = params[:role]
    create_team_user team: team, user: user, role: role
    render_success 'team', team.reload
  end

  def new_team
    user = User.where(email: params[:email]).last
    User.current = user
    t = create_team params
    User.current = nil
    render_success 'team', t.reload
  end

  def update_tag_texts
    t = Team.find(params[:team_id])
    params[:tags].to_s.split(',').each{ |text| TagText.create(text: text, team_id: params[:team_id]) }
    t.save
    render_success 'team', t
  end

  def new_project
    t = Team.find(params[:team_id])
    Team.current = t
    p = params[:use_default_project] ? t.default_folder : create_project(params)
    Team.current = nil
    render_success 'project', p
  end

  def new_session
    user = User.where(email: params[:email]).last
    User.current = user
    request.env['devise.mapping'] = Devise.mappings[:api_user]
    sign_in user
    User.current = nil
    render_success 'user', current_api_user
  end

  def new_claim
    new_media 'claim'
  end

  def new_link
    new_media 'link'
  end

  def new_source
    Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
    User.current = user
    source = Source.new
    source.name = params[:name]
    source.slogan = params[:slogan]
    source.skip_check_ability = true
    source.save!
    User.current = nil
    Team.current = nil
    render_success 'source', source
  end

  def media_status
    pm = ProjectMedia.find(params[:pm_id])
    s = pm.last_status_obj
    s.status = params[:status]
    s.save!
    render_success 'project_media', pm
  end

  def new_media_tag
    user = User.where(email: params[:email]).last
    pm = ProjectMedia.find(params[:pm_id])
    tag = create_tag tag: params[:tag], annotated: pm, annotator: user
    pm.save!
    render_success 'project_media', pm
  end

  def new_task
    user = User.where(email: params[:email]).last
    pm = ProjectMedia.find(params[:pm_id])
    t = create_task({ annotated: pm, annotator: user }.merge(params.permit(params.keys)))
    render_success 'task', t
  end

  def new_team_data_field
    type = params[:type] || 'free_text'
    Team.current = Team.find(params[:team_id])
    team_data_field = "Team-#{params[:fieldset]}-#{Time.now}"
    options = []
    if params[:options]
      options = JSON.parse(params[:options])
    end
    tt = create_team_task(params.permit(params.keys).merge({label: team_data_field, team_id: params[:team_id], fieldset: params[:fieldset], task_type: type, options: options }))
    render_success 'team_task', tt
  end

  def new_api_key
    if params[:access_token]
      a = ApiKey.where(access_token: params[:access_token]).last
      unless a.nil?
        render_success 'api_key', a
        return true
      end
    end
    a = create_api_key(params)
    params.each do |key, value|
      a.send("#{key}=", value) if a.respond_to?("#{key}=")
    end
    a.save!
    render_success 'api_key', a
  end

  def get
    klass = params[:class].camelize
    obj = klass.constantize.find(params[:id])
    ret = {}
    params[:fields].split(',').each do |field|
      ret[field] = obj.send(field) if obj.respond_to?(field)
    end
    render_success params[:class], ret
  end

  def new_bot
    b = create_team_bot name: 'Testing Bot', set_approved: true, login: random_string
    render_success 'bot', b
  end

  def archive_project
    p = Project.find(params[:project_id])
    p.archived = CheckArchivedFlags::FlagCodes::TRASHED
    p.save!
    render_success 'project', p
  end

  def new_dynamic_annotation
    type = params[:annotation_type]
    fields = {}
    set_fields = {}
    types = params[:types].split(',')
    n = types.size
    values = params[:values].split(',', n)
    params[:fields].split(',', n).each_with_index do |field, i|
      fields[field] = [types[i], false]
      set_fields[type + '_' + field] = values[i]
    end
    create_annotation_type_and_fields(type, fields)
    d = create_dynamic_annotation annotated_id: params[:annotated_id], annotated_type: params[:annotated_type], annotation_type: type, set_fields: set_fields.to_json
    if params[:set_action]
      d = Dynamic.find(d.id)
      d.action = params[:set_action]
      d.save!
    end
    render_success 'dynamic_annotation', { graphql_id: d.graphql_id }
  end

  def new_cache_key
    Rails.cache.write(params[:key], params[:value])
    render_success 'cache_key', { params[:key] => params[:value] }
  end

  def suggest_similarity_item
    Team.current = Team.find(params[:team_id])
    pm1 = params[:pm1]
    pm2 = params[:pm2]
    create_relationship source_id: pm1, target_id: pm2 ,relationship_type: Relationship.suggested_type
    render_success 'suggest_similarity', pm1
  end

  def create_imported_standalone_fact_check
    team = Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
    description = params[:description]
    context = params[:context]
    title = params[:title]
    summary = params[:summary]
    url = params[:url]
    language = params[:language] || 'en'

    project_media = ProjectMedia.create!(media: Blank.create!, team: team, user: user)

    # Create ClaimDescription
    claim_description = ClaimDescription.create!(
      description: description,
      context: context,
      user: user,
      team: team,
      project_media: project_media
    )

    # Set up FactCheck
    fact_check = FactCheck.new(
      claim_description: claim_description,
      title: title,
      summary: summary,
      url: url,
      language: language,
      user: user,
      publish_report: true,
      report_status: 'published'
    )
    fact_check.save!
    render_success 'fact_check', fact_check
  end

  def random
    render html: "<!doctype html><html><head><title>Test #{rand(100000).to_i}</title></head><body>Test</body></html>".html_safe
  end

  def create_saved_search_list
    team = Team.current = Team.find(params[:team_id])
    saved_search = create_saved_search(team: team)

    render_success 'saved_search', saved_search
  end

  def create_feed
    team = Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
    saved_search = team.saved_searches.first || SavedSearch.create!(
      title: "#{user.name.capitalize}'s list",
      team: team,
      filters: { created_by: user }
    )

    feed_params = {
      name: "Feed for #{team.name} ##{team.feeds.count + 1}",
      user: user,
      team: team,
      published: true,
      saved_search: saved_search,
      licenses: [1],
      last_clusterized_at: Time.now,
      data_points: [1, 2]
    }

    feed = Feed.create!(feed_params)

    # pm = create_project_media(
    #   project: saved_search.team.projects.first,
    #   quote: 'Test',
    #   media_type: 'Claim'
    # )
    # puts "project media: ", pm.inspect

    pm = ProjectMedia.new
    pm.project_id = saved_search.team.projects.first.id
    pm.quote = 'Test'
    pm.media_type = 'Claim'.camelize
    pm.save!

    cluster = Cluster.new
    cluster.project_media = pm
    cluster.feed = feed
    cluster.save!

    ClusterProjectMedia.create!(
      cluster: cluster,
      project_media: pm
    )
  
    render_success 'feed', { feed: feed, cluster: cluster, project_media: pm }
  end

  def create_feed_invitation
    team = Team.current = Team.find(params[:team_id])
    user = User.where(email: params[:email]).last
    feed = team.feeds.first || create_feed(team: team, user: user)
  
    feed_invitation_params = {
      email: user.email,
      feed: feed,
      user: user,
      state: :invited
    }
  
    feed_invitation = FeedInvitation.create!(feed_invitation_params)

    puts feed_invitation.inspect
    render_success 'feed_invitation', feed_invitation
  end

  protected

  def new_media(type)
    Team.current = Team.find(params[:team_id])
    user = params[:email].blank? ? nil : User.where(email: params[:email]).last
    User.current = user
    pm = ProjectMedia.new
    pm.project_id = params[:project_id]
    pm.quote = params[:quote] if type == 'claim'
    pm.url = params[:url] if type == 'link'
    pm.media_type = type.camelize
    pm.save!
    User.current = nil
    Team.current = nil
    render_success 'project_media', pm
  end

  private

  def check_environment
    (render(plain: 'Only available in test mode', status: 400) and return) unless Rails.env === 'test'
  end

  def init_bot_events
    BotUser.init_event_queue if Rails.env.test?
  end

  def trigger_bot_events
    BotUser.trigger_events if Rails.env.test?
  end
end
