include SampleData
require "faker"

data = {
    team_name: Faker::Company.name,
    user_name: Faker::Name.first_name.downcase,
    user_password: Faker::Internet.password(min_length: 8),
    link_media_links: [
        'https://meedan.com/post/q-a-with-watching-western-sahara-bringing-one-of-the-worlds-most-invisible-crises-to-the-spotlight-through-citizen-journalism-and-cinema', 
        'https://meedan.com/post/q-a-with-meedan-partner-digital-rights-foundation-on-digital-rights-and-gender-violence-in-south-asia', 
        'https://meedan.com/post/meedan-supports-hyperlocal-efforts-to-tackle-climate-misinformation',
        'https://meedan.com/post/users-are-moving-to-the-decentralized-web-after-musks-twitter-takeover-heres-what-that-means-for-verification',
        'https://meedan.com/post/five-content-moderation-takeaways-from-elon-musks-twitter-takeover',
        'https://meedan.com/post/meedan-supports-spanish-language-fact-checking-on-whatsapp-ahead-of-u-s-midterms',
        'https://meedan.com/post/save-alaa-abdel-fatah',
        'https://meedan.com/post/announcing-the-2021-meedan-annual-report',
        'https://meedan.com/post/meedan-and-national-democratic-institute-release-recommendations-for-ending-online-violence-against-women-in-politics',
        'https://meedan.com/post/q-a-with-cite-a-zimbabwean-innovation-hub-tracking-promises-by-politicians'
    ],
    audios: ['e-item.mp3', 'rails.mp3', 'with_cover.mp3', 'with_cover.ogg', 'with_cover.wav'],
    images: ['large-image.jpg', 'maçã.png', 'rails-photo.jpg', 'rails.png', 'rails2.png', 'ruby-big.png', 'ruby-small.png'],
    videos: ['d-item.mp4', 'rails.mp4'],
    fact_check_links: [
        'https://meedan.com/post/addressing-global-challenges-through-regional-interventions', 
        'https://meedan.com/post/exploring-the-use-of-offline-games-for-media-literacy-and-misinformation-education', 
        'https://meedan.com/post/op-ed-heres-what-were-considering-in-the-lead-up-to-the-supreme-courts-decisions-on-the-future-of-the-internet',
        'https://meedan.com/post/meedan-impact-story-using-ai-to-investigate-weapons-trafficking-and-human-rights-violations',
        'https://meedan.com/post/meedan-partner-fatabyyano-launches-tipline-for-earthquake-crisis-response',
        'https://meedan.com/post/feminist-publication-magdalene-investigates-beauty-misinformation-on-social-media',
        'https://meedan.com/post/meedan-announces-earthquake-crisis-response-for-media-covering-turkey-and-syria',
        'https://meedan.com/post/meedan-labs-welcomes-orlando-watson-and-louis-moynihan-as-senior-advisors',
        'https://meedan.com/post/meedan-supported-fact-checking-consortium-in-india-welcomes-five-new-members-ahead-of-india-elections',
        'https://meedan.com/post/five-trends-we-found-on-whatsapp-during-the-2022-brazil-elections'
    ],
    quotes: ['Garlic can help you fight covid', 'Tea with garlic is a covid treatment', 'If you have covid you should eat garlic', 'Are you allergic to garlic?', 'Vampires can\'t eat garlic']
}

def open_file(file)
    File.open(File.join(Rails.root, 'test', 'data', file))
end

p '...Seeding...'
p 'Making Team...'
team = create_team(name: Faker::Company.name)

p 'Making User...'
user = create_user(name: data[:user_name], login: data[:user_name], password: data[:user_password], password_confirmation: data[:user_password], email: Faker::Internet.safe_email(name: data[:user_name]), is_admin: true)

p 'Making Project...'
project = create_project(title: team.name, team_id: team.id, user: user, description: '') 

p 'Making Team User...'
create_team_user(team: team, user: user, role: 'admin')

p 'Making Medias...'
medias = []

p 'Making Medias: Claims...'
10.times { medias.push(Claim.create!(user_id: user.id, quote: Faker::Quotes::Shakespeare.hamlet_quote)) }

p 'Making Medias: Links...'
data[:link_media_links].each { |link_media_link| medias.push(Link.create!(user_id: user.id, url: link_media_link)) }

p 'Making Medias: Audios...'
data[:audios].each { |audio| medias.push(UploadedAudio.create!(user_id: user.id, file: open_file(audio))) }

p 'Making Medias: Images...'
data[:images].each { |image| medias.push(UploadedImage.create!(user_id: user.id, file: open_file(image)))} 

p 'Making Medias: Videos...'
data[:videos].each { |video| medias.push(UploadedVideo.create!(user_id: user.id, file: open_file(video))) }

p 'Making Project Medias for medias...'
medias.each { |media| ProjectMedia.create!(user_id: user.id, project: project, team: team, media: media) }


p 'Making Claim Descriptions and Fact Checks...'
def fact_check_attributes(fact_check_link, user, project, team)
    {
      summary: Faker::Company.catch_phrase,
      url: fact_check_link,
      title: Faker::Company.name,
      user: user,
      claim_description: create_claim_description(user, project, team)
    }
end

def create_blank(project, team)
    ProjectMedia.create!(project: project, team: team, media: Blank.create!)
end

def create_claim_description(user, project, team)
    ClaimDescription.create!(description: Faker::Lorem.paragraph(sentence_count: 10), context: Faker::Lorem.sentence, user: user, project_media: create_blank(project, team))
end

data[:fact_check_links].each { |fact_check_link| create_fact_check(fact_check_attributes(fact_check_link, user, project, team)) }

p 'Making Relationship between Claims...'
claims = []
project_medias_for_claims = []
data[:quotes].each { |quote| claims.push(Claim.create!(user_id: user.id, quote: quote)) }
claims.each { |claim| project_medias_for_claims.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: claim))}

Relationship.create!(source_id: project_medias_for_claims[0].id, target_id: project_medias_for_claims[1].id, relationship_type: Relationship.confirmed_type)
Relationship.create!(source_id: project_medias_for_claims[0].id, target_id: project_medias_for_claims[2].id, relationship_type: Relationship.confirmed_type)
Relationship.create!(source_id: project_medias_for_claims[3].id, target_id: project_medias_for_claims[4].id, relationship_type: Relationship.suggested_type)

p 'Making Relationship between Images...'
project_medias_for_images = []
2.times { project_medias_for_images.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedImage.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.png'))))) }
Relationship.create!(source_id: project_medias_for_images[0].id, target_id: project_medias_for_images[1].id, relationship_type: Relationship.confirmed_type)

p 'Making Relationship between Audios...'
project_medias_for_audio = []
2.times { project_medias_for_audio.push(ProjectMedia.create!(user_id: user.id, project: project, team: team, media: UploadedAudio.create!(user_id: user.id, file: File.open(File.join(Rails.root, 'test', 'data', 'rails.mp3'))))) }
Relationship.create!(source_id: project_medias_for_audio[0].id, target_id: project_medias_for_audio[1].id, relationship_type: Relationship.confirmed_type)


p "Created — user: #{data[:user_name]} — email: #{user.email} — password : #{data[:user_password]}"

