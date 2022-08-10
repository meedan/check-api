# bundle exec rake check:import_from_fato_ou_fake_csv

require 'open-uri'
require 'nokogiri'
require 'bitly'
require 'open_uri_redirections'

BITLY_TOKEN = ''
PROJECT_ID = nil
TEAM_SLUG = ''

namespace :check do
  desc 'Import data for Fato ou Fake and populate in Check by creating items and reports.'
  task import_from_fato_ou_fake_csv: :environment do
    RequestStore.store[:skip_rules] = true
    RequestStore.store[:skip_notifications] = true

    bitly = Bitly::API::Client.new(token: BITLY_TOKEN)

    team = Team.find_by_slug(TEAM_SLUG)
    project = Project.where(id: PROJECT_ID, team_id: team.id).last

    data = CSV.parse(File.read(File.dirname(__FILE__) + '/input.csv'), { headers: true }).map(&:to_h)
    n = data.size
    i = 0
    data.each do |line|
      i += 1

      original_image = begin
                         image = line['imagem'] || 'no-image'
                         open("#{File.dirname(__FILE__)}/images/#{image}")
                       rescue
                         nil
                       end
      html = begin
               Nokogiri::HTML(open(line['saibamais'], allow_redirections: :all))
             rescue
               puts "Not available: #{line['saibamais']}"
               next
             end
      title = begin
                html.at_css('h1.content-head__title').text
              rescue
                puts "Could not get the title!"
                next
              end
      report_image = begin
                       open(html.css('figure amp-img').last.attr('srcset').split(', ').collect{ |u| u.gsub(/ .*$/, '') }.first, allow_redirections: :all)
                     rescue
                       nil
                     end
      link = bitly.shorten(long_url: line['saibamais']).link
      date = begin Time.parse(line['saibamais'].match(/[0-9]{4}\/[0-9]{2}\/[0-9]{2}/)[0].gsub('/', '-')) rescue nil end
      text = [line['boato'], line['mensagem']].map(&:to_s).join("\n\n")

      analysis_title = title
      analysis_content = line['explicacao'].to_s
      if original_image
        analysis_title = line['boato']
        analysis_content = line['mensagem']
      end

      # Create media
      
      create_params = original_image ? { type: 'UploadedImage' } : { quote: text, type: 'Claim' }
      m = Media.new(create_params)
      m.file = original_image if original_image
      m.save!

      # Create project media

      pm = ProjectMedia.create!(media: m, team: team, add_to_project_id: project.id)
      
      # Update project media timestamps
      
      unless date.nil?
        ActiveRecord::Base.record_timestamps = false
        update_params = {
          created_at: date,
          updated_at: date
        }
        pm = ProjectMedia.find(pm.id)
        update_params.each do |key, value|
          pm.send("#{key}=", value)
        end
        pm.save!
        ActiveRecord::Base.record_timestamps = true
      end

      # Analysis and Status

      label = '#' + line['selo'].strip.upcase
      status = team.media_verification_statuses['statuses'].find{ |s| s['label'] == label || s['locales']['pt_BR']['label'] == label }['id']
      s = pm.last_status_obj
      s.skip_check_ability = true
      s.skip_notifications = true
      s.set_fields = {
        verification_status_status: status,
        title: analysis_title.to_s,
        content: analysis_content.to_s,
        published_article_url: link.to_s,
        date_published: date.to_i,
        external_id: line['id'].to_s,
        raw: line.to_json
      }.to_json
      s.save!

      # Report

      report = Dynamic.new
      report.annotation_type = 'report_design'
      report.annotated = pm
      begin
        report.file = [report_image] if report_image
      rescue
        puts "Could not set report image!"
        report.file = nil
      end
      fields = {
        state: 'paused',
        options: [{
          language: 'pt_BR',
          title: title,
          text: [line['explicacao'], link].join("\n"),
          status_label: label.upcase,
          use_visual_card: true,
          headline: '',
          description: title.truncate(240),
          image: '',
          use_introduction: true,
          introduction: 'Sua mensagem enviada em {{query_date}} foi classificada como {{status}}',
          theme_color: pm.reload.last_status_color,
          url: '',
          use_text_message: true,
          date: date ? "Checagem publicada em: #{report.report_design_date(date.to_date, 'pt-BR').downcase}" : ''
        }]
      }
      report.set_fields = fields.to_json
      report.action = 'save'
      report.save!

      if report_image && report.file && report.file[0]
        report = Dynamic.find(report.id)
        data = report.data
        data['options'][0]['image'] = report.file[0].file.public_url
        report.set_fields = data.to_json
        report.save!
      end

      puts "#{i}/#{n}) #{Time.now}"
      puts "Date: #{date}"
      puts "Title: #{title}"
      puts "Link: #{link}"
      puts "Original image: #{original_image}"
      puts "Report image: #{report_image}"
      puts
    end

    RequestStore.store[:skip_rules] = false
    RequestStore.store[:skip_notifications] = false
  end
end
