include SampleData
require "faker"
require "byebug"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
end

LINKS_PARAMS = [
  'https://meedan.com/post/addressing-misinformation-across-countries-a-pioneering-collaboration-between-taiwan-factcheck-center-vera-files',
  'https://meedan.com/post/entre-becos-a-women-led-hyperlocal-newsletter-from-the-peripheries-of-brazil',

  'https://meedan.com/post/check-global-launches-independent-media-response-fund-tackles-on-climate-misinformation',
  'https://meedan.com/post/chambal-media',
  'https://meedan.com/post/application-process-for-the-check-global-independent-media-response-fund',
  'https://meedan.com/post/fact-checkers-and-their-mental-health-research-work-in-progress',
  'https://meedan.com/post/meedan-stands-with-rappler-in-the-fight-against-disinformation',
  'https://meedan.com/post/2022-french-elections-meedan-software-supported-agence-france-presse',
  'https://meedan.com/post/how-to-write-longform-git-commits-for-better-software-development',
  'https://meedan.com/post/welcome-smriti-singh-our-research-intern',
  'https://meedan.com/post/countdown-to-u-s-2024-meedan-coalition-to-exchange-critical-election-information-with-overlooked-voters',
  'https://meedan.com/post/a-statement-on-the-israel-gaza-war-by-meedans-ceo',
  'https://meedan.com/post/resources-to-capture-critical-evidence-from-the-israel-gaza-war',
  'https://meedan.com/post/turkeys-largest-fact-checking-group-debunks-election-related-disinformation',
  'https://meedan.com/post/meedan-joins-diverse-cohort-of-partners-committed-to-partnership-on-ais-responsible-practices-for-synthetic-media',
  'https://meedan.com/post/nurturing-equity-diversity-and-inclusion-meedans-people-first-approach',
  'https://meedan.com/post/students-find-top-spreader-of-climate-misinformation-is-most-read-online-news-publisher-in-egypt',
  'https://meedan.com/post/new-e-course-on-the-fundamentals-of-climate-and-environmental-reporting-in-africa',
  'https://meedan.com/post/annual-report-2022',
  'https://meedan.com/post/meedan-joins-partnership-on-ais-ai-and-media-integrity-steering-committee'
].map do |url|
    { type: 'Link', url: url+"?timestamp=#{Time.now.to_f}" }
  end

CLAIMS_PARAMS = (Array.new(20) do
  {
    type: 'Claim',
    quote: Faker::Lorem.paragraph(sentence_count: 10)
  }
end)

UPLOADED_AUDIOS_PARAMS = (['e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav']*4).map do |audio|
  { type: 'UploadedAudio', file: open_file(audio) }
end

UPLOADED_IMAGES_PARAMS =  (['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'ruby-small.png']*4).map do |image|
  { type: 'UploadedImage', file: open_file(image) }
end

UPLOADED_VIDEOS_PARAMS =  (['d-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4']*4).map do |video|
  { type: 'UploadedVideo', file: open_file(video) }
end

MEDIAS_PARAMS = [
  *CLAIMS_PARAMS,
  *LINKS_PARAMS,
  *UPLOADED_AUDIOS_PARAMS,
  *UPLOADED_IMAGES_PARAMS,
  *UPLOADED_VIDEOS_PARAMS
].shuffle!

class Setup

  private

  attr_reader :user_names, :user_passwords, :user_emails, :team_names, :existing_user_email, :main_user_a

  public

  attr_reader :teams, :users

  def initialize(existing_user_email)
    @existing_user_email = existing_user_email
    @user_names = Array.new(3) { Faker::Name.first_name.downcase }
    @user_passwords = Array.new(3) { Faker::Internet.password(min_length: 8) }
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

  attr_reader :teams, :users, :invited_teams

  public

  def initialize(setup)
    @teams = setup.teams
    @users = setup.users
    @invited_teams = teams.size > 1
  end

  def populate_projects
    projects_params_main_user_a = 
      {
        title: "#{teams[:main_team_a][:name]} / [a] Main User: Main Team",
        user: users[:main_user_a],
        team: teams[:main_team_a],
        project_medias_attributes: MEDIAS_PARAMS.map.with_index { |media_params, index|
          {
            media_attributes: media_params,
            user: users[:main_user_a],
            team: teams[:main_team_a],
            claim_description_attributes: {
              description: claim_title(media_params),
              context: Faker::Lorem.sentence,
              user: users[:main_user_a],
              fact_check_attributes: fact_check_params_for_half_the_claims(index, users[:main_user_a]),
            }
          }
        }
      }

    Project.create!(projects_params_main_user_a)

    if invited_teams
      project_params_invited_users = 
      [
        {
          title: "#{teams[:invited_team_b1][:name]} / [b] Invited User: Project Team #1",
          user: users[:invited_user_b],
          team: teams[:invited_team_b1],
          project_medias_attributes: CLAIMS_PARAMS.map.with_index { |media_params, index|
            {
              media_attributes: media_params,
              user: users[:invited_user_b],
              team: teams[:invited_team_b1],
              claim_description_attributes: {
                description: claim_title(media_params),
                context: Faker::Lorem.sentence,
                user: users[:invited_user_b],
                fact_check_attributes: fact_check_params_for_half_the_claims(index, users[:invited_user_b]),
              }
            }
          }
        },
        {
          title: "#{teams[:invited_team_b2][:name]} / [b] Invited User: Project Team #2",
          user: users[:invited_user_b],
          team: teams[:invited_team_b2],
          project_medias_attributes: CLAIMS_PARAMS.map.with_index { |media_params, index|
            {
              media_attributes: media_params,
              user: users[:invited_user_b],
              team: teams[:invited_team_b2],
              claim_description_attributes: {
                description: claim_title(media_params),
                context: Faker::Lorem.sentence,
                user: users[:invited_user_b],
                fact_check_attributes: fact_check_params_for_half_the_claims(index, users[:invited_user_b]),
              }
            }
          }
        },
        {
          title: "#{teams[:invited_team_c][:name]} / [c] Invited User: Project Team #1",
          user: users[:invited_user_c],
          team: teams[:invited_team_c],
          project_medias_attributes: CLAIMS_PARAMS.map.with_index { |media_params, index|
            {
              media_attributes: media_params,
              user: users[:invited_user_c],
              team: teams[:invited_team_c],
              claim_description_attributes: {
                description: claim_title(media_params),
                context: Faker::Lorem.sentence,
                user: users[:invited_user_c],
                fact_check_attributes: fact_check_params_for_half_the_claims(index, users[:invited_user_c]),
              }
            }
          }
        }
      ]

      project_params_invited_users.each { |params| Project.create!(params) }
    end
  end

  def publish_fact_checks
    users.each_value do |user|
      fact_checks = FactCheck.where(user: user).last(10)
      fact_checks[0, fact_checks.size/2].each { |fact_check| verify_fact_check_and_publish_report(fact_check.project_media)}
    end
  end

  def saved_searches
    teams.each_value { |team| saved_search(team) }
  end

  def share_feeds
    return unless invited_teams
    invited_users = [ users[:invited_user_b], users[:invited_user_c] ]
    main_team_a_saved_search = SavedSearch.where(team: teams[:main_team_a]).first

    feed = feed(main_team_a_saved_search)
    invited_users.each { |invited_user| feed_invitation(feed, invited_user)}
  end

  def confirm_relationships
    teams_project_medias.each_value do |project_medias|
      confirmed_relationship(project_medias[0],  project_medias[1..3])
      confirmed_relationship(project_medias[4], project_medias[5])
      confirmed_relationship(project_medias[6], project_medias[7])
      confirmed_relationship(project_medias[8], project_medias[1])
    end
  end

  def suggest_relationships
    teams_project_medias.each_value do |project_medias|
      suggested_relationship(project_medias[8], project_medias[14..19])
    end
  end

  def tipline_requests
    teams_project_medias.each_value do |project_medias|
      create_tipline_requests(project_medias.values_at(0,3,6,9,12,15,18), 1)
      create_tipline_requests(project_medias.values_at(1,4,7,10,13,16,19), 15)
      create_tipline_requests(project_medias.values_at(2,5,8,11,14,17), 17)
    end
  end

  private

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

    saved_search_params = {
      title: "#{user.name.capitalize}'s list",
      team: team,
      filters: {created_by: user}
    }

    if team.saved_searches.empty?
      SavedSearch.create!(saved_search_params)
    else
      team.saved_searches.first
    end
  end

  def feed(saved_search)
    feed_params = {
      name: "Feed Test ##{users[:main_user_a].feeds.count + 1}",
      user: users[:main_user_a],
      team: teams[:main_team_a],
      published: true,
      saved_search: saved_search,
      licenses: [1],
      data_points: [1,2]
    }
    Feed.create!(feed_params)
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
    [children].flatten.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.confirmed_type) }
  end

  def suggested_relationship(parent, children)
    children.each { |child| Relationship.create!(source_id: parent.id, target_id: child.id, relationship_type: Relationship.suggested_type)}
  end

  def teams_project_medias
    @teams_project_medias ||= teams.transform_values { |team| team.project_medias.to_a }
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
    smooch_data = {
      'role': 'appUser',
      'source': {
        'type': ['whatsapp', 'telegram', 'messenger'].sample,
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

    TiplineRequest.create!(
      associated: project_media,
      team_id: project_media.team_id,
      smooch_request_type: ['default_requests', 'timeout_search_requests', 'relevant_search_result_requests'].sample,
      smooch_data: smooch_data,
      smooch_report_received_at: [Time.now.to_i, nil].sample,
      user_id:  BotUser.smooch_user&.id
    )
  end

  def create_tipline_requests(project_medias, x_times)
    project_medias.each {|project_media| x_times.times {create_tipline_user_and_data(project_media)}}
  end
end

puts "If you want to create a new user: press enter"
puts "If you want to add more data to an existing user: Type user email then press enter"
print ">> "
answer = STDIN.gets.chomp

puts "—————"
puts "Stretch your legs, this might take a while."
puts "On a mac took about 10 minutes to create all populated workspaces."
puts "—————"

begin
  puts 'Creating users and teams...'
  setup = Setup.new(answer.presence) # .presence : returns nil or the string
  puts 'Creating projects for all users...'
  populated_workspaces = PopulatedWorkspaces.new(setup)
  populated_workspaces.populate_projects
  puts 'Creating saved searches for all teams...'
  populated_workspaces.saved_searches
  puts 'Making and inviting to Shared Feed... (won\'t run if you are not creating any invited users)'
  populated_workspaces.share_feeds
  puts 'Making Confirmed Relationships between items...'
  populated_workspaces.confirm_relationships
  puts 'Making Suggested Relationships between items...'
  populated_workspaces.suggest_relationships
  puts 'Making Tipline requests...'
  populated_workspaces.tipline_requests
  puts 'Publishing half of each user\'s Fact Checks...'
  populated_workspaces.publish_fact_checks
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
  
Rails.cache.clear
