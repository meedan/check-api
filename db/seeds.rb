include SampleData
require "faker"
require "byebug"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

def open_file(file)
  File.open(File.join(Rails.root, 'test', 'data', file))
end

class Setup
  attr_reader :user_passwords, :user_emails, :teams, :users

  def initialize(existing_user)
    @existing_user = existing_user
    @user_names = Array.new(3) { Faker::Name.first_name.downcase }
    @user_passwords = Array.new(3) { Faker::Internet.password(min_length: 8) }
    @user_emails = @user_names.map { |name| Faker::Internet.safe_email(name: name) }
    @team_names = Array.new(4) { Faker::Company.name }

    create_users
    create_teams
    create_team_users
  end

  def create_users
    puts "create users"
    @users ||= begin

      all_users = {
        invited_user_b:
        {
          name: @user_names[1] + ' [b / invited user]',
          login: @user_names[1] + ' [b / invited user]',
          email: @user_emails[1],
          password: @user_passwords[1],
          password_confirmation: @user_passwords[1]
        },
        invited_user_c:
        {
          name: @user_names[2] + ' [c / invited user]',
          login: @user_names[2] + ' [c / invited user]',
          email: @user_emails[2],
          password: @user_passwords[2],
          password_confirmation: @user_passwords[2]
        }
      }.transform_values { |params| User.create!(params) }

      all_users[:main_user_a] = create_or_fetch_main_user_a
      all_users.each_value { |user| user.confirm && user.save! }
      all_users
    end
  end

  def create_teams
    puts "create teams"
    @teams ||= begin
    
      all_teams = {
        invited_team_b1:
        {
          name: "#{@team_names[1]} / [b] Invited User: Team #1",
          slug: Team.slug_from_name(@team_names[1]),
          logo: open_file('maçã.png')
        },
        invited_team_b2:
        {
          name: "#{@team_names[2]} / [b] Invited User: Team #2",
          slug: Team.slug_from_name(@team_names[2]),
          logo: open_file('ruby-small.png')
        },
        invited_team_c:
        {
          name: "#{@team_names[3]} / [c] Invited User: Team #1",
          slug: Team.slug_from_name(@team_names[3]),
          logo: open_file('maçã.png')
        }
      }.transform_values { |t| Team.create!(t) }

      all_teams[:main_team_a] = create_or_fetch_main_team_a
      all_teams
    end
  end 

  private

  def create_or_fetch_main_user_a
    @main_user_a ||= if @existing_user
    # if @existing_user
      User.find_by(email: @existing_user)
    else
      User.create!({
        name: @user_names[0] + ' [a / main user]',
        login: @user_names[0] + ' [a / main user]',
        email: @user_emails[0],
        password: @user_passwords[0],
        password_confirmation: @user_passwords[0],
      })
    end
  end

  def create_or_fetch_main_team_a
    if @main_user_a.teams.first
      @main_user_a.teams.first
    else
      Team.create!({
        name: "#{@team_names[0]} / [a] Main User: Main Team",
        slug: Team.slug_from_name(@team_names[0]),
        logo: open_file('rails.png')
      })
    end
  end

  def create_team_users
    [
      {
        team: @teams[:invited_team_b1],
        user: @users[:invited_user_b],
        role: 'admin',
        status: 'member'
      },
      {
        team: @teams[:invited_team_b2],
        user: @users[:invited_user_b],
        role: 'admin',
        status: 'member'
      },
      {
        team: @teams[:invited_team_c],
        user: @users[:invited_user_c],
        role: 'admin',
        status: 'member'
      }
    ].each { |params| TeamUser.create!(params) }

    create_or_fetch_main_team_a_team_user
  end

  def create_or_fetch_main_team_a_team_user
    return if @existing_user
    TeamUser.create!({
      team: @teams[:main_team_a],
      user: @users[:main_user_a],
      role: 'admin',
      status: 'member'
    })
  end
end

class PopulatedProjects
  def initialize(setup)
    @teams = setup.teams
    @users = setup.users
    @medias_params = get_medias_params
  end

  def create_populated_projects
    puts 'create populated projects'
    projects_params = [
      {
        title: "#{@teams[:main_team_a][:name]} / [a] Main User: Main Team",
        user: @users[:main_user_a],
        team: @teams[:main_team_a],
        project_medias_attributes: @medias_params.map { |media_params|
          {
            media_attributes: media_params,
            team: @teams[:main_team_a],
          }
        }
      },
      {
        title: "#{@teams[:invited_team_b1][:name]} / [b] Invited User: Project Team #1",
        user: @users[:invited_user_b],
        team: @teams[:invited_team_b1],
        project_medias_attributes: @medias_params.map { |media_params|
          {
            media_attributes: media_params,
            team: @teams[:invited_team_b1],
          }
        }
      },
      {
        title: "#{@teams[:invited_team_b2][:name]} / [b] Invited User: Project Team #2",
        user: @users[:invited_user_b],
        team: @teams[:invited_team_b2],
        project_medias_attributes: @medias_params.map { |media_params|
          {
            media_attributes: media_params,
            team: @teams[:invited_team_b2],
          }
        }
      },
      {
        title: "#{@teams[:invited_team_c][:name]} / [c] Invited User: Project Team #1",
        user: @users[:invited_user_c],
        team: @teams[:invited_team_c],
        project_medias_attributes: @medias_params.map { |media_params|
          {
            media_attributes: media_params,
            team: @teams[:invited_team_c],
          }
        }
      }
    ]

    projects_params.each { |params| Project.create!(params) }
  end

  private
  def get_medias_params
    links = [
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
        { type: 'Link', url: url }
      end
    claims = (Array.new(20) do
      {
        type: 'Claim',
        quote: Faker::Lorem.paragraph(sentence_count: 10)
      }
    end)
    uploadedAudios = (['e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav']*4).map do |audio|
      { type: 'UploadedAudio', file: open_file(audio) }
    end
    uploadedImages =  (['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'ruby-small.png']*4).map do |image|
      { type: 'UploadedImage', file: open_file(image) }
    end
    uploadedVideos =  (['d-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4']*4).map do |video|
      { type: 'UploadedVideo', file: open_file(video) }
    end

    [
      # *links,
      *claims,
      # *uploadedAudios,
      # *uploadedImages,
      # *uploadedVideos
    ]
  end
end

puts "If you want to create a new user: press enter"
puts "If you want to add more data to an existing user: Type user email then press enter"
print ">> "
answer = STDIN.gets.chomp

puts "Stretch your legs, this might take a while"

setup = Setup.new(answer.presence) # .presence : returns nil or the string
PopulatedProjects.new(setup).create_populated_projects



# teams.each do |team|
#   project_medias = team.project_medias

#   create_confirmed_relationship(project_medias[0],  project_medias[1..3])
#   create_confirmed_relationship(project_medias[4], project_medias[5])
#   create_confirmed_relationship(project_medias[6], project_medias[7])
#   create_confirmed_relationship(project_medias[8], project_medias[1])
# end

puts 'emails'
setup.user_emails.each { |e| puts e }
puts 'passwords'
setup.user_passwords.each { |p| puts p }

Rails.cache.clear
