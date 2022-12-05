class AdjustReportDesignSchema < ActiveRecord::Migration[5.2]
  def change
    RequestStore.store[:skip_rules] = true

    at = DynamicAnnotation::AnnotationType.where(annotation_type: 'report_design').last
    unless at.nil?
      json_schema = at.json_schema.clone.with_indifferent_access
      options_schema = json_schema[:properties][:options][:items]
      json_schema[:properties][:options] = options_schema
      
      at.json_schema = json_schema
      at.save!

      # We need to do this in the migration, otherwise the app can be inconsistent

      n = Dynamic.where(annotation_type: 'report_design').count
      i = 0
      Dynamic.where(annotation_type: 'report_design').find_each do |report|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Updating report with ID #{report.id}..."
        data = report.data.with_indifferent_access
        data[:options] = data[:options].first
        report.data = data
        report.save!
      end
    end

    RequestStore.store[:skip_rules] = false
  end
end
namespace :check do
  namespace :migrate do
    task adjust_report_design_schema: :environment do
      started = Time.now.to_i
      RequestStore.store[:skip_rules] = true
      n = Dynamic.where(annotation_type: 'report_design').count
      i = 0
      failed_items = []
      Dynamic.where(annotation_type: 'report_design').find_each do |report|
        i += 1
        puts "[#{Time.now}] (#{i}/#{n}) Updating report with ID #{report.id}..."
        data = report.data.with_indifferent_access
        options = data[:options] || []
        data[:options] = options.length ? options.shift : {}
        selected_option = nil
        if options.length && data[:options][:title].blank? && data[:options][:text].blank?
          selected_option = options.find{|e| !e[:title].blank? || !e[:text].blank? }
        end
        data[:options] = selected_option unless selected_option.nil?       
        report.data = data
        begin
          report.save!
        rescue
          failed_items << report.id
        end
      end
      RequestStore.store[:skip_rules] = false
      minutes = ((Time.now.to_i - started) / 60).to_i
      puts "[#{Time.now}] Done in #{minutes} minutes."
      puts "Failed items: #{failed_items.inspect}" if failed_items.length > 0
    end
  end
end
