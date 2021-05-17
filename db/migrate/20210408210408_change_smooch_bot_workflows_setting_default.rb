class ChangeSmoochBotWorkflowsSettingDefault < ActiveRecord::Migration
  def change
    tb = BotUser.smooch_user
    unless tb.nil?
      settings = tb.get_settings.clone || []
      i = settings.find_index{ |s| s['name'] == 'smooch_workflows' }
      if i >= 0
        settings[i]['default'] = [
          {
            "smooch_workflow_language" => "en",
            "smooch_message_smooch_bot_greetings" => "Hi! Welcome to our fact-checking bot.",
            "smooch_state_main" => {
              "smooch_menu_message" =>
                "📌*Main Menu*\n" +
                "\n" +
                "*Reply 1* (or 🔍) to submit a request for a fact-check about an article, video, image, or other content.\n" +
                "*Reply 2* (or \u{1F9A0}) to get the latest information about coronavirus disease (COVID-19)",
              "smooch_menu_options" => [
                {
                  "smooch_menu_option_keyword" => "1",
                  "smooch_menu_option_value" => "query_state",
                  "smooch_menu_project_media_title" => "",
                  "smooch_menu_project_media_id" => ""
                },
                {
                  "smooch_menu_option_keyword" => "2",
                  "smooch_menu_option_value" => "secondary_state",
                  "smooch_menu_project_media_title" => "",
                  "smooch_menu_project_media_id" => ""
                }
              ]
            },
            "smooch_state_secondary" => {
              "smooch_menu_message" =>
                "*Information about Coronavirus disease (COVID-19)* \u{1F9A0}\n" +
                "\n" +
                "👉*Reply with any one of the following numbers (or emoji) to get information about that topic:*\n" +
                "\n" +
                "*1:* How do I protect myself and/or my family? 👨👩👧\n" +
                "*2:* I think I might be getting sick 🤒\n" +
                "*3:* How can I handle stress associated with COVID-19? ❤️\n" +
                "*4:* Information about cases and recoveries globally 📊\n" +
                "*5:* Latest updates from the World Health Organization 🌐\n" +
                "\n" +
                "*Reply 0* to get back to the *Main Menu* 📌",
              "smooch_menu_options" => [
                {
                  "smooch_menu_option_keyword" => "0",
                  "smooch_menu_option_value" => "main_state",
                  "smooch_menu_project_media_title" => "",
                  "smooch_menu_project_media_id" => ""
                }
              ]
            },
            "smooch_state_query" => {
              "smooch_menu_message" =>
                "👉 *Please enter the question, link, picture or video that you want fact-checked* followed by any context or additional questions related to that item.\n" +
                "\n" +
                "❗️You must submit *one* claim or item to be fact-checked per request.\n" +
                "\n" +
                "Reply 0 to cancel your request.",
              "smooch_menu_options" => [
                {
                  "smooch_menu_option_keyword" => "0",
                  "smooch_menu_option_value" => "main_state",
                  "smooch_menu_project_media_title" => "",
                  "smooch_menu_project_media_id" => ""
                }
              ]
            },
            "smooch_message_smooch_bot_message_confirmed" =>
              "Thank you! Your request has been received. Responses are being aggregated and sorted, and we're working on fact-checking your questions.\n" +
              "\n" +
              "✔️*Follow this link for an updated list of common questions that we have fact-checked:* [ Link to a page of fact-checks on your website ]\n" +
              "\n" +
              "👉*Reply with any text* to get back to the *Main Menu* 📌",
            "smooch_message_smooch_bot_option_not_available" => "🤖I'm sorry, I didn't understand your message. Please try again!",
            "smooch_message_smooch_bot_result_changed" => "❗The fact-check that we sent to you has been *updated* with new information:",
            "smooch_message_smooch_bot_message_type_unsupported" =>
              "❌Sorry, we can't accept this type of message for verification at this time.\n" +
              "\n" +
              "We can accept most images, videos, links, text messages, and shared WhatsApp messages.",
            "smooch_message_smooch_bot_disabled" =>
              "❌Thank you for your message. Our fact-checking service is currently *inactive.*\n" +
              "\n" +
              "Contact us at *[email or other contact]* for further inquiries."
          }
        ]
        tb.set_settings(settings)
        tb.save!
      end
    end
  end
end
