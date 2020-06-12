# Disclaimer: This is just a prototype and still a work in progress
# bundle exec rake check:import_claim_reviews[data_url,team_id,status_identifier]

require 'open-uri'

namespace :check do
  desc 'Import ClaimReview data from external service and populate in Check by creating/updating items and reports.'
  task import_claim_reviews: :environment do |_t, args|
    RequestStore.store[:skip_notifications] = true
    data_url = args.to_a[0]
    team = Team.find(args.to_a[1].to_i)
    status = args.to_a[2]
    puts "Importing/updating data into team #{team.name}"

    # Parse the input data
    
    data = open(data_url) { |f| JSON.parse(f.read) }
    puts "Going to import #{data.size} claims..."

    i = 0
    data.each do |item|
      i += 1
      puts "[#{Time.now}] Import #{i}/#{data.size}..."

      # Get some data

      headline = item.dig('raw_claim', 'headline')
      image = item.dig('raw_claim', 'image')
      tmp = File.join(Rails.root, 'tmp', 'image')
      if image
        open(image['url']) do |i|
          File.open(tmp, 'wb') do |f|
            f.write(i.read)
          end
        end
      end

      # Create media
      
      create_params = image ? { type: 'UploadedImage' } : { quote: headline, type: 'Claim' }
      m = Media.new(create_params)
      if image
        File.open(tmp) do |f|
          m.file = f
        end
        FileUtils.rm_f(tmp)
      end
      m.save!

      # Create project media

      pm = ProjectMedia.create!(media: m, team: team)
      
      # Update project media timestamps
      
      ActiveRecord::Base.record_timestamps = false
      update_params = {
        created_at: Time.parse(item.dig('raw_claim', 'datePublished')),
        updated_at: Time.parse(item.dig('raw_claim', 'dateModified'))
      }
      pm = ProjectMedia.find(pm.id)
      update_params.each do |key, value|
        pm.send("#{key}=", value)
      end
      pm.save!
      ActiveRecord::Base.record_timestamps = true

      # Set title

      pm.metadata = { title: headline }.to_json
      pm.save!

      # Create language annotation
      
      language = item.dig('raw_claim', 'inLanguage')
      Dynamic.create!(annotated: pm, annotation_type: 'language', set_fields: { language: language }.to_json) unless language.blank?
      
      # Create tags
      
      keywords = item.dig('raw_claim', 'keywords').split(',').collect{ |k| k.strip }.uniq.sort
      keywords.each do |keyword|
        Tag.create!(annotated: pm, tag: keyword)
      end

      # Change status

      s = pm.last_status_obj
      if status
        s.status = status
        s.save!
      end
      pm = ProjectMedia.find(pm.id)

      # Create a published report

      report = Dynamic.new
      report.annotation_type = 'report_design'
      report.annotated = pm
      report.set_fields = {
        state: 'published',
        status_label: pm.status_i18n(pm.last_verification_status),
        description: item.dig('raw_claim', 'articleBody'),
        headline: headline,
        use_visual_card: true,
        image: image ? image['url'] : '',
        use_introduction: false,
        introduction: '',
        theme_color: pm.last_status_color,
        url: item.dig('raw_claim', 'publisher', 'url'),
        use_text_message: true,
        text: [item.dig('raw_claim', 'articleBody'), item.dig('raw_claim', 'url')].join("\n\n"),
        use_disclaimer: false,
        disclaimer: ''
      }.to_json
      report.save!
      report.report_image_generate_png
    
      RequestStore.store[:skip_notifications] = false
    end
  end
end
