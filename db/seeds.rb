include SampleData
require "faker"
require "byebug"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
end

# claims and uploaded files can be the same
# links need different timestamps, so they are created for each user
CLAIMS_PARAMS = (Array.new(8) do
  {
    type: 'Claim',
    quote: Faker::Lorem.paragraph(sentence_count: 8)
  }
end)

UPLOADED_AUDIO_PARAMS = (['e-item.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav']*2).map do |audio|
  { type: 'UploadedAudio', file: open_file(audio) }
end

UPLOADED_IMAGE_PARAMS =  (['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'ruby-small.png']*2).map do |image|
  { type: 'UploadedImage', file: open_file(image) }
end

UPLOADED_VIDEO_PARAMS =  (['d-item.mp4', 'rails.mp4']*4).map do |video|
  { type: 'UploadedVideo', file: open_file(video) }
end

LINK_PARAMS = -> {[
  'https://meedan.com/post/addressing-misinformation-across-countries-a-pioneering-collaboration-between-taiwan-factcheck-center-vera-files',
  'https://meedan.com/post/entre-becos-a-women-led-hyperlocal-newsletter-from-the-peripheries-of-brazil',
  'https://meedan.com/post/check-global-launches-independent-media-response-fund-tackles-on-climate-misinformation',
  'https://meedan.com/post/chambal-media',
  'https://meedan.com/post/application-process-for-the-check-global-independent-media-response-fund',
  'https://meedan.com/post/new-e-course-on-the-fundamentals-of-climate-and-environmental-reporting-in-africa',
  'https://meedan.com/post/annual-report-2022',
  'https://meedan.com/post/meedan-joins-partnership-on-ais-ai-and-media-integrity-steering-committee',
].map do |url|
    { type: 'Link', url: url+"?timestamp=#{Time.now.to_f}" }
  end
}

BLANK_PARAMS = Array.new(8, { type: 'Blank' })

STANDALONE_CLAIMS_FACT_CHECKS_PARAMS = (Array.new(8) do
  {
    description: Faker::Lorem.sentence,
    context: Faker::Lorem.paragraph(sentence_count: 8)
  }
end)

class Setup

  private

  attr_reader :user_names, :user_passwords, :user_emails, :team_names, :existing_user_email, :main_user_a

  public

  attr_reader :teams, :users

  def initialize(existing_user_email)
    @existing_user_email = existing_user_email
    @user_names = Array.new(3) { Faker::Name.first_name.downcase }
    @user_passwords = Array.new(3) { random_complex_password }
    @user_emails = @user_names.map { |name| Faker::Internet.safe_email(name: name) }
    @team_names = Array.new(4) { Faker::Company.name }

    users
    teams
    team_users
  end

  def get_users_emails_and_passwords
    login_credentials = user_emails.zip(user_passwords)
    if existing_user_email && teams.size > 1
      login_credentials[1..]
    elsif existing_user_email && teams.size == 1
      ['Added to a user, and did not create any new users.']
    elsif teams.size == 1
      login_credentials[0]
    else
      login_credentials
    end.flatten
  end

  def users
    @users ||= begin
      all_users = {}
      all_users.merge!(invited_users)
      all_users[:main_user_a] = main_user_a
      all_users.each_value { |user| user.confirm && user.save! }
      all_users
    end
  end

  def teams
    @teams ||= begin
      all_teams = {}
      all_teams.merge!(invited_teams)
      all_teams[:main_team_a] = main_team_a
      all_teams
    end
  end

  private

  def main_user_a
    @main_user_a ||= if existing_user_email
      User.find_by(email: existing_user_email)
    else
      User.create!({
        name: user_names[0] + ' [a / main user]',
        login: user_names[0] + ' [a / main user]',
        email: user_emails[0],
        password: user_passwords[0],
        password_confirmation: user_passwords[0],
      })
    end
  end

  def main_team_a
    if main_user_a.teams.first
      main_user_a.teams.first
    else
      Team.create!({
        name: "#{team_names[0]} / [a] Main User: Main Team",
        slug: Team.slug_from_name(team_names[0]),
        logo: open_file('rails.png')
      })
    end
  end

  def invited_users
    {
      invited_user_b:
      {
        name: user_names[1] + ' [b / invited user]',
        login: user_names[1] + ' [b / invited user]',
        email: user_emails[1],
        password: user_passwords[1],
        password_confirmation: user_passwords[1]
      },
      invited_user_c:
      {
        name: user_names[2] + ' [c / invited user]',
        login: user_names[2] + ' [c / invited user]',
        email: user_emails[2],
        password: user_passwords[2],
        password_confirmation: user_passwords[2]
      }
    }.transform_values { |params| User.create!(params) }
  end

  def invited_teams
    {
      invited_team_b1:
      {
        name: "#{team_names[1]} / [b] Invited User: Team #1",
        slug: Team.slug_from_name(team_names[1]),
        logo: open_file('maçã.png')
      },
      invited_team_b2:
      {
        name: "#{team_names[2]} / [b] Invited User: Team #2",
        slug: Team.slug_from_name(team_names[2]),
        logo: open_file('ruby-small.png')
      },
      invited_team_c:
      {
        name: "#{team_names[3]} / [c] Invited User: Team #1",
        slug: Team.slug_from_name(team_names[3]),
        logo: open_file('maçã.png')
      }
    }.transform_values { |t| Team.create!(t) }
  end

  def team_users
    if teams.size > 1
      [
        {
          team: teams[:invited_team_b1],
          user: users[:invited_user_b],
          role: 'admin',
          status: 'member'
        },
        {
          team: teams[:invited_team_b2],
          user: users[:invited_user_b],
          role: 'admin',
          status: 'member'
        },
        {
          team: teams[:invited_team_c],
          user: users[:invited_user_c],
          role: 'admin',
          status: 'member'
        }
      ].each { |params| TeamUser.create!(params) }
    end

    main_team_a_team_user
  end

  def main_team_a_team_user
    return if @existing_user_email
    TeamUser.create!({
      team: teams[:main_team_a],
      user: users[:main_user_a],
      role: 'admin',
      status: 'member'
    })
  end
end

class PopulatedWorkspaces

  private

  attr_reader :teams, :users, :invited_teams, :bot

  public

  def initialize(setup)
    @teams = setup.teams
    @users = setup.users
    @invited_teams = teams.size > 1
    @bot = BotUser.fetch_user
  end

  def fetch_bot_installation
    teams.each_value do |team|
      installation = TeamBotInstallation.where(team: team, user: bot).last
      bot.install_to!(team) if installation.nil?
    end
  end

  def populate_project_medias
    project_media_params = [{
      user: users[:main_user_a],
      team: teams[:main_team_a],
    }]
    if invited_teams
      project_media_params.concat([
        {
          user: users[:invited_user_b],
          team: teams[:invited_team_b1],
        },
        {
          user: users[:invited_user_b],
          team: teams[:invited_team_b2],
        },
        {
          user: users[:invited_user_c],
          team: teams[:invited_team_c],
        }
      ])
    end
    project_media_params.each do |params|
      medias_params.map.with_index do |media_params, index|
        params.merge!({
          channel: channel(media_params[:type]),
          media_attributes: media_params,
          claim_description_attributes: {
            description: claim_title(media_params),
            context: Faker::Lorem.sentence,
            user: media_params[:type] == "Blank" ? bot : params[:user],
            fact_check_attributes: imported_fact_check_params(media_params[:type]) || fact_check_params_for_half_the_claims(index, params[:user]),
          }
        })
        ProjectMedia.create!(params)
      end
    end
  end

  def publish_fact_checks
    users.each_value do |user|
      fact_checks = user.claim_descriptions.where.not(project_media_id: nil).includes(:fact_check).map { |claim| claim.fact_check }.compact!.last(items_total/2)
      fact_checks[0, (fact_checks.size/2)].each { |fact_check| verify_fact_check_and_publish_report(fact_check.project_media)}
    end
  end

  def saved_searches
    teams.each_value { |team| saved_search(team) }
  end

  def explainers
    teams.each_value { |team| 5.times { create_explainer(team) } }
    teams.each_value { |team| 5.times { create_imported_explainer(team) } }
  end

  def main_user_feed(to_be_shared)
    if to_be_shared == "share_media"
      data_points = [2]
      last_clusterized_at = nil
      saved_search = { media_saved_search: SavedSearch.where(team: teams[:main_team_a], list_type: 'media').first }
    elsif to_be_shared == "share_everything"
      data_points = [1,2]
      last_clusterized_at = Time.now
      saved_search = {
        media_saved_search: SavedSearch.where(team: teams[:main_team_a], list_type: 'media').first,
        article_saved_search: SavedSearch.where(team: teams[:main_team_a], list_type: 'article').first
      }
    end

    feed_params = {
      name: "Feed Test ##{users[:main_user_a].feeds.count + 1}",
      user: users[:main_user_a],
      team: teams[:main_team_a],
      published: true,
      licenses: [1],
      last_clusterized_at: last_clusterized_at,
      data_points: data_points
    }.merge(saved_search)
    Feed.create!(feed_params)
  end

  def share_feed(feed)
    return unless invited_teams
    invited_users = [ users[:invited_user_b], users[:invited_user_c] ]
    invited_users.each { |invited_user| feed_invitation(feed, invited_user)}
  end

  def accept_invitation(feed, invited_user)
    team = users[invited_user].teams.first
    feed_invitation = FeedInvitation.where(feed_id: feed.id).find_by(email: users[invited_user].email)
    feed_invitation.accept!(team.id)
  end

  def clusters(feed)
    feed_project_medias_groups = feed_project_medias(feed).in_groups(3, false)

    c1_centre = feed_project_medias_groups.first.delete_at(0)
    c1_project_media = [c1_centre]
    c2_centre = feed_project_medias_groups.first.first
    c2_project_medias = feed_project_medias_groups.first
    c3_centre = feed_project_medias_groups.second.first
    c3_project_medias = feed_project_medias_groups.second
    c4_centre = feed_project_medias_groups.third.first
    c4_project_medias = feed_project_medias_groups.third

    c1 = cluster(c1_centre, feed, c1_centre.team_id)
    c2 = cluster(c2_centre, feed, c2_centre.team_id)
    c3 = cluster(c3_centre, feed, c3_centre.team_id)
    c4 = cluster(c3_centre, feed, c4_centre.team_id)

    cluster_items(c1_project_media, c1)
    cluster_items(c2_project_medias, c2)
    cluster_items(c3_project_medias, c3)
    cluster_items(c4_project_medias, c4)

    updated_cluster(c1)
    updated_cluster(c2)
    updated_cluster(c3)
    updated_cluster(c4)
  end

  def confirm_relationships
    teams_project_medias.each_value do |project_medias|
      confirmed_relationship(project_medias[0],  project_medias[1])
      confirmed_relationship(project_medias[2],  project_medias[3..items_total/2])
    end
  end

  def suggest_relationships
    teams_project_medias.each_value do |project_medias|
      suggested_relationship(project_medias[2], project_medias[(items_total/2)+1..items_total-1])
    end
  end

  def tipline_requests
    teams_project_medias.each_value do |team_project_medias|
      create_tipline_requests(team_project_medias)
    end
  end

  def verified_standalone_claims_and_fact_checks
    users.each_value do |user|
      standalone_claims_and_fact_checks(user)
      verify_standalone_claims_and_fact_checks(user)
    end
  end

  private

  def medias_params
    [
      *CLAIMS_PARAMS,
      *UPLOADED_AUDIO_PARAMS,
      *UPLOADED_IMAGE_PARAMS,
      *UPLOADED_VIDEO_PARAMS,
      *BLANK_PARAMS,
      *LINK_PARAMS.call
    ].shuffle!
  end

  def items_total
    @items_total ||= medias_params.size
  end

  def title_from_link(link)
    path = URI.parse(link).path
    path.remove('/post/').underscore.humanize
  end

  def claim_title(media_params)
    media_params[:type] == "Link" ? title_from_link(media_params[:url]) : Faker::Company.catch_phrase
  end

  def fact_check_params_for_half_the_claims(index, user)
    if index.even?
      {
        summary: Faker::Company.catch_phrase,
        title: Faker::Company.name,
        user: user,
        language: 'en',
        url: get_url_for_some_fact_checks(index)
      }
    else
      {
        summary:  '',
      }
    end
  end

  def get_url_for_some_fact_checks(index)
    index % 4 == 0 ? "https://www.thespruceeats.com/step-by-step-basic-cake-recipe-304553?timestamp=#{Time.now.to_f}" : nil
  end

  def verify_fact_check_and_publish_report(project_media)
    status = ['verified', 'false'].sample

    verification_status = project_media.last_status_obj
    verification_status.status = status
    verification_status.save!

    report_design = project_media.get_dynamic_annotation('report_design')
    report_design.set_fields = { status_label: status, state: 'published' }.to_json
    report_design.action = 'publish'
    report_design.save!
  end

  def saved_search(team)
    user = team.team_users.find_by(role: 'admin').user

    media_saved_search_params = {
      title: "#{user.name.capitalize}'s media list",
      team: team,
      filters: {created_by: user},
      list_type: 'media',
    }
    article_saved_search_params = {
      title: "#{user.name.capitalize}'s article list",
      team: team,
      filters: {created_by: user},
      list_type: 'article',
    }

    if team.saved_searches.empty?
      SavedSearch.create!(media_saved_search_params)
      SavedSearch.create!(article_saved_search_params)
    else
      team.saved_searches.first
    end
  end

  def create_explainer(team)
    Explainer.create!({
      title: Faker::Lorem.sentence,
      url: random_url,
      description: Faker::Lorem.paragraph(sentence_count: 8),
      team: team,
      user: users[:main_user_a],
    })
  end

  def create_imported_explainer(team)
    Explainer.create!({
      title: Faker::Lorem.sentence,
      url: random_url,
      description: Faker::Lorem.paragraph(sentence_count: 8),
      team: team,
      user: bot,
      channel: random_imported_article_channel
    })
  end

  def feed_invitation(feed, invited_user)
    feed_invitation_params = {
      email: invited_user.email,
      feed: feed,
      user: users[:main_user_a],
      state: :invited
    }
    FeedInvitation.create!(feed_invitation_params)
  end

  def confirmed_relationship(parent, children)
    [children].flatten.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.confirmed_type, user_id: child.user_id) }
  end

  def suggested_relationship(parent, children)
    children.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.suggested_type, user_id: child.user_id)}
  end

  def teams_project_medias
    @teams_project_medias ||= teams.transform_values { |team| team.project_medias.last(items_total).to_a }
  end

  def create_tipline_user_and_data(project_media)
    tipline_message_data = {
      link: 'https://www.nytimes.com/interactive/2023/09/28/world/europe/russia-ukraine-war-map-front-line.html',
      audio: "#{random_url}/wnHkwjykxOqU3SMWpEpuVzSa.oga",
      video: "#{random_url}/AOVFpYOfMm_ssRUizUQhJHDD.mp4",
      image: "#{random_url}/bOoeoeV9zNA51ecial0eWDG6.jpeg",
      facebook: 'https://www.facebook.com/boomlive/posts/pfbid0ZoZPYTQAAmrrPR2XmpZ2BCPED1UgozxFGxSQiH68Aa6BF1Cvx2uWHyHrFrAwK7RPl',
      instagram: 'https://www.instagram.com/p/CxsV1Gcskk8/?img_index=1',
      tiktok: 'https://www.tiktok.com/@235flavien/video/7271360629615758597?_r=1&_t=8fFCIWTDWVt',
      twitter: 'https://twitter.com/VietFactCheck/status/1697642909883892175',
      youtube: 'https://www.youtube.com/watch?v=4EIHB-DG_JA',
      text: Faker::Lorem.paragraph(sentence_count: 10)
    }

    tipline_user_name = Faker::Name.first_name.downcase
    tipline_user_surname = Faker::Name.last_name
    tipline_message =  tipline_message_data.values.sample((1..10).to_a.sample).join(' ')
    phone = [ Faker::PhoneNumber.phone_number, Faker::PhoneNumber.cell_phone, Faker::PhoneNumber.cell_phone_in_e164, Faker::PhoneNumber.phone_number_with_country_code, Faker::PhoneNumber.cell_phone_with_country_code].sample
    uid = random_string

    # Tipline user
    smooch_user_data = {
      'id': uid,
      'raw': {
        '_id': uid,
        'givenName': tipline_user_name,
        'surname': tipline_user_surname,
        'signedUpAt': Time.now.to_s,
        'properties': {},
        'conversationStarted': true,
        'clients': [
          {
            'id': random_string,
            'status': 'active',
            'externalId': phone,
            'active': true,
            'lastSeen': Time.now.to_s,
            'platform': 'whatsapp',
            'integrationId': random_string,
            'displayName': phone,
            'raw': {
              'profile': {
                'name': tipline_user_name
              },
              'from': phone
            }
          }
        ],
        'pendingClients': []
      },
      'identifier': random_string,
      'app_name': random_string
    }

    fields = {
      smooch_user_id: uid,
      smooch_user_app_id: random_string,
      smooch_user_data: smooch_user_data.to_json
    }

    Dynamic.create!(annotation_type: 'smooch_user', annotated: project_media.team, annotator: BotUser.smooch_user, set_fields: fields.to_json)

    # Tipline request
    plataform = ['whatsapp', 'telegram', 'messenger'].sample
    smooch_data = {
      'role': 'appUser',
      'source': {
        'type': plataform,
        'id': random_string,
        'integrationId': random_string,
        'originalMessageId': random_string,
        'originalMessageTimestamp': Time.now.to_i
      },
      'authorId': uid,
      'name': tipline_user_name,
      '_id': random_string,
      'type': 'text',
      'received': Time.now.to_f,
      'text': tipline_message,
      'language': 'en',
      'mediaUrl': nil,
      'mediaSize': 0,
      'archived': 3,
      'app_id': random_string
    }

    mapping = {'whatsapp'=> CheckChannels::ChannelCodes::WHATSAPP, 'telegram' => CheckChannels::ChannelCodes::TELEGRAM, 'messenger'=>CheckChannels::ChannelCodes::MESSENGER}
    project_media.update_columns(channel: {main: project_media.channel['main'], others: project_media.channel['others'].to_a.push(mapping[plataform]).uniq} )

    TiplineRequest.create!(
      associated: project_media,
      team_id: project_media.team_id,
      smooch_request_type: smooch_request_type,
      smooch_data: smooch_data,
      smooch_report_received_at: [Time.now.to_i, nil].sample,
      user_id:  BotUser.smooch_user&.id
    )
  end

  def smooch_request_type
    ['default_requests', 'timeout_search_requests', ['relevant_search_result_requests', 'irrelevant_search_result_requests']*3].flatten.sample
  end

  def create_tipline_requests(team_project_medias)
    team_project_medias.each_with_index do |project_media, index|
      if index.even?
        create_tipline_user_and_data(project_media)
      elsif index % 3 == 0
        17.times {create_tipline_user_and_data(project_media)}
      end
    end
  end

  def feed_project_medias(feed)
    teams_not_on_feed = teams.reject { |team_name, team| team.is_part_of_feed?(feed.id) }
    teams_project_medias_clone = teams_project_medias.clone
    teams_not_on_feed.each_key { |team_name| teams_project_medias_clone.delete(team_name)}
    teams_project_medias_clone.compact_blank!.values.flatten!
  end

  def cluster_items(project_medias, cluster)
    project_medias.each { |pm| ClusterProjectMedia.create!(cluster_id: cluster.id, project_media_id: pm.id) }
  end

  def updated_cluster(cluster)
    cluster_project_medias = cluster.items
    cluster_fact_checks = cluster_project_medias.map { |project_media| project_media.claim_description.fact_check }.compact!
    cluster_tipline_requests = cluster_project_medias.map { |project_media| project_media.get_requests }.flatten!

    cluster.media_count = cluster_project_medias.size
    cluster.last_item_at = cluster_project_medias.last.created_at
    cluster.team_ids = cluster.items.pluck(:team_id).uniq
    unless cluster_fact_checks.nil? || cluster_fact_checks.empty?
      cluster.fact_checks_count = cluster_fact_checks.size
      cluster.last_fact_check_date = last_date(cluster_fact_checks)
    end
    unless cluster_tipline_requests.nil? || cluster_tipline_requests.empty?
      cluster.requests_count = cluster_tipline_requests.size
      cluster.last_request_date = last_date(cluster_tipline_requests)
    end
    cluster.save!
  end

  def last_date(collection)
    collection.sort { |a,b| a.created_at <=> b.created_at }.last.created_at
  end

  def random_channels
    channels = [5, 6, 7, 8, 9, 10, 13]
    channels.sample(rand(channels.size))
  end

  def cluster(project_media, feed, team_id)
    cluster_params = {
      project_media_id: project_media.id,
      first_item_at: project_media.created_at,
      feed_id: feed.id,
      team_ids: [team_id],
      channels: random_channels,
      title: project_media.title
    }
    Cluster.create!(cluster_params)
  end

  def imported_fact_check_params(media_type)
    if media_type == 'Blank'
      {
        summary: Faker::Company.catch_phrase,
        title: Faker::Company.name,
        user: bot,
        language: 'en',
        url: get_url_for_some_fact_checks(4),
        channel: random_imported_article_channel,
      }
    else
      false
    end
  end

  def random_imported_article_channel
    channels = ['api', 'zapier', 'imported']
    channels.sample
  end

  def channel(media_type)
    media_type == "Blank" ? { main: CheckChannels::ChannelCodes::FETCH } : { main: CheckChannels::ChannelCodes::MANUAL }
  end

  def standalone_claims_and_fact_checks(user)
    STANDALONE_CLAIMS_FACT_CHECKS_PARAMS.each.with_index do |params, index|
      claim_description_attributes = {
        description: params[:description],
        context: params[:context],
        user: user,
        team: user.teams[0],
        fact_check_attributes: fact_check_params_for_half_the_claims(index, user),
      }

      ClaimDescription.create!(claim_description_attributes)
    end
  end

  def verify_standalone_claims_and_fact_checks(user)
    status = ['undetermined', 'not_applicable', 'in_progress', 'verified', 'false']

    fact_checks = user.claim_descriptions.where(project_media_id: nil).includes(:fact_check).map { |claim| claim.fact_check }.compact! # some claims don't have fact checks, so they return nil
    fact_checks.each do |fact_check|
      fact_check.rating = status.sample
      fact_check.save!
    end
  end
end

puts "If you want to create a new user: press enter"
puts "If you want to add more data to an existing user: Type user email then press enter"
print ">> "
answer = STDIN.gets.chomp

puts "—————"
puts "Stretch your legs, this might take a while."
puts "On a mac took about 10 minutes to create all populated workspaces."
puts "Keep track of the queues: http://localhost:3000/sidekiq"
puts "The workspaces will be fully finished when those finish running"
puts "—————"

ActiveRecord::Base.transaction do
  begin
    puts 'Creating users and teams...'
    setup = Setup.new(answer.presence) # .presence : returns nil or the string
    puts 'Creating project medias for all users...'
    populated_workspaces = PopulatedWorkspaces.new(setup)
    populated_workspaces.fetch_bot_installation
    populated_workspaces.populate_project_medias
    puts 'Creating saved searches for all teams...'
    populated_workspaces.saved_searches
    puts 'Creating feed...'
    feed_1 = populated_workspaces.main_user_feed("share_media")
    feed_2 = populated_workspaces.main_user_feed("share_everything")
    puts 'Making and inviting to Shared Feed... (won\'t run if you are not creating any invited users)'
    populated_workspaces.share_feed(feed_1)
    populated_workspaces.share_feed(feed_2)
    puts 'Accepting invitation to a Shared Feed...'
    populated_workspaces.accept_invitation(feed_2, :invited_user_c)
    puts 'Making Confirmed Relationships between items...'
    populated_workspaces.confirm_relationships
    puts 'Making Suggested Relationships between items...'
    populated_workspaces.suggest_relationships
    puts 'Making Tipline requests...'
    populated_workspaces.tipline_requests
    puts 'Publishing half of each user\'s Fact Checks...'
    populated_workspaces.publish_fact_checks
    puts 'Creating Clusters...'
    populated_workspaces.clusters(feed_2)
    puts 'Creating Explainers...'
    populated_workspaces.explainers
    puts 'Creating Standalone Claims and FactChecks with different statuses...'
    populated_workspaces.verified_standalone_claims_and_fact_checks
  rescue RuntimeError => e
    if e.message.include?('We could not parse this link')
      puts "—————"
      puts "Creating Items failed: Couldn't create Links. \nMake sure Pender is running, or comment out Links so they are not created."
      puts "—————"
    else
      raise e
    end
  end

  unless e
    puts "—————"
    puts "Created users:"
    setup.get_users_emails_and_passwords.each { |user_info| puts user_info }
  end
end

Rails.cache.clear
