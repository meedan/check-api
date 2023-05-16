class AddNewsletterTemplateNamesToSmoochBot < ActiveRecord::Migration[6.0]
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      # Add new template settings for newsletters
      header_types = ['none', 'image', 'video'] # "none" is used for link preview and "video" is used for audio
      number_of_articles = ['no', 'one', 'two', 'three']
      header_types.each do |header_type|
        number_of_articles.each do |number_of_articles|
          template_name = "newsletter_#{header_type}_#{number_of_articles}_articles"
          settings << {
            name: "smooch_template_name_for_#{template_name}",
            label: "Template name for template '#{template_name}'",
            type: 'string',
            default: ''
          }
        end
      end
      tb.set_settings(settings)
      tb.save!
    end
  end
end
