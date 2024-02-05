include SampleData
require "faker"

Rails.env.development? || raise('To run the seeds file you should be in the development environment')

user_names = Array.new(3) { Faker::Name.first_name.downcase }
user_passwords = Array.new(3) { Faker::Internet.password(min_length: 8) }
team_names = Array.new(4) { Faker::Company.name }

users_params = {
  main_user_a:
  {
    name: user_names[0] + ' [a / main user]',
    email: Faker::Internet.safe_email(name: user_names[0]),
    password: user_passwords[0]
  },
  invited_user_b:
  {
    name: user_names[1] + ' [b / invited user]',
    email: Faker::Internet.safe_email(name: user_names[1]),
    password: user_passwords[1]
  },
  invited_user_c:
  {
    name: user_names[2] + ' [c / invited user]',
    email: Faker::Internet.safe_email(name: user_names[2]),
    password: user_passwords[2]
  }
}

teams_params = 
{
  main_team_a:
  {
    name: "#{team_names[0]} / [a] Main User: Main Team",
    logo: 'rails.png'
  },
  invited_team_b1:
  {
    name: "#{team_names[1]} / [b] Invited User: Team #1",
    logo: 'maçã.png'
  },
  invited_team_b2:
  {
    name: "#{team_names[2]} / [b] Invited User: Team #2",
    logo: 'ruby-small.png'
  },
  invited_team_c:
  {
    name: "#{team_names[3]} / [c] Invited User: Team #1",
    logo: 'maçã.png'
  }
}

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
  { type: 'UploadedAudio', file: audio }
end
uploadedImages =  (['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'ruby-small.png']*4).map do |image|
  { type: 'UploadedImage', file: image }
end
uploadedVideos =  (['d-item.mp4', 'rails.mp4', 'd-item.mp4', 'rails.mp4', 'd-item.mp4']*4).map do |video|
  { type: 'UploadedVideo', file: video }
end

medias_params = [
  *links,
  *claims,
  *uploadedAudios,
  *uploadedImages,
  *uploadedVideos
]

projects_params = [
  {
    title: "#{team_names[0]} / [a] Main User: Main Team",
    user_attributes: users_params[:main_user_a],
    team_attributes: teams_params[:main_team_a],
    project_medias_attributes: medias_params.map { |mp|
      {
        media_attributes: mp,
      }
    }
  },
  {
    title: "#{team_names[0]} / [b] Invited User: Project Team #1",
    user_attributes: users_params[:invited_user_b],
    team_attributes: teams_params[:invited_team_b1],
    project_medias_attributes: [{
      media_attributes: medias_params[1],
    }]
  },
  {
    title: "#{team_names[0]} / [b] Invited User: Project Team #2",
    user_attributes: users_params[:invited_user_b],
    team_attributes: teams_params[:invited_team_b2],
    project_medias_attributes: [{
      media_attributes: medias_params[1],
    }]
  },
  {
    title: "#{team_names[0]} / [c] Invited User: Project Team #1",
    user_attributes: users_params[:invited_user_c],
    team_attributes: teams_params[:invited_team_c],
    project_medias_attributes: [{
      media_attributes: medias_params[1],
    }]
  }
]

projects = projects_params.each { |params| Project.create!(params) }
users_params.each_value { |u| puts u[:email], u[:name], u[:password] }
projects.each { |p| puts p }

Rails.cache.clear
