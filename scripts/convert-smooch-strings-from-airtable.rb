require 'csv'
require 'json'

input = ARGV[0] # CSV from Airtable
strings = {}

# Airtable ID => Check string ID
SKIP = 'SKIP'
MAPPING = {
  add_more_button: :add_more_details_state_button_label,
  back_to_menu_button: :main_menu,
  back_to_menu_text: SKIP, # Not used currently, because on the non-WhatsApp platforms, the main menu is always appended to the final messages
  cancel_button: [:main_state_button_label, :ask_if_ready_state_button_label],
  cancel_text: SKIP, # Not used currently, because on the non-WhatsApp platforms, it is build dynamically with a number + the string above
  invalid_format: :invalid_format,
  language_confirmation: :confirm_preferred_language,
  language_confirmation_text: SKIP, # Not used currently, because on the non-WhatsApp platforms, the text is the same as the one above
  navigation_button: SKIP, # Not used currently
  navigation_text: SKIP, # Not used currently
  newsletter_header: SKIP, # Not used currently... it's still a setting (actually one per language) under the tipline settings
  no_button: :search_result_is_not_relevant_button_label,
  privacy_and_purpose: SKIP, # Please see app/models/concerns/smooch_tos.rb
  report_updated: :report_updated,
  submit_button: :search_state_button_label,
  subscribe_button: :subscribe_button_label,
  unsubscribe_button: :unsubscribe_button_label,
  subscription_status_negative: :unsubscribed,
  subscription_status_positive: :subscribed,
  yes_button: :search_result_is_relevant_button_label,
  language_button: :languages,
  privacy_statement_option: :privacy_statement,
  languages_privacy_section: :languages_and_privacy_title,
  privacy_section: :privacy_title,
  keep_subscription: SKIP, # To be used in CHECK-1590
  newsletter_notification: SKIP, # To be used in CHECK-1548
  newsletter_footer_text: SKIP # Not used currently
}

MISSING_IN_AIRTABLE = {}

LANGUAGES = {
  '00 - English' => :en,
  'Bahasa Indonesia' => :id,
  'Bengali' => :be,
  'French' => :fr,
  'German' => :de,
  'Hindi' => :hi,
  'Kannada' => :kn,
  'Marathi' => :mr,
  'Portuguese' => :pt,
  'Punjabi' => :pa,
  'Spanish' => :es,
  'Tamil' => :ta,
  'Telugu' => :te,
  'Urdu' => :ur
}

strings = strings.merge(MISSING_IN_AIRTABLE)

i = 0
CSV.foreach(input, headers: true) do |row|
  i += 1
  data = row.to_h
  if data['Status'] =~ /Done/ || data['Language'] == '00 - English'
    id = data.values.first.to_s.strip.downcase
    raise "ID missing for row #{i}" if id.nil?
    key = MAPPING[id.to_sym]
    lang = LANGUAGES[data['Language'].to_s.strip]
    raise "Language mapping not found: #{data['Language']}" if lang.nil?
    raise "ID mapping not found: #{id}" if key.nil?
    unless key == 'SKIP'
      raise "Content is blank for ID #{id} and language #{data['Language']}" if data['Content'].nil?
      [key].flatten.each do |k|
        strings[k] ||= {}
        strings[k][lang] = data['Content'].strip
      end
    end
  end
end

# Make sure we have at least English for all strings
strings.each do |key, value|
  raise "Missing English translation for #{key}!" unless value[:en]
end

# Make sure that all strings are there
expected = MAPPING.values.reject{ |v| v == SKIP }.collect{ |v| [v].flatten }.flatten
actual = strings.keys
diff = (expected - actual)
raise "Missing strings: #{diff.join(', ')}" if diff.size > 0

o = File.open(File.join(File.expand_path(File.dirname(__FILE__)), '..', 'app', 'models', 'concerns', 'smooch_strings.rb'), 'w+')
o.puts %{
# Please update this file using the script at scripts/convert-smooch-strings-from-airtable.rb
require 'active_support/concern'

module SmoochStrings
  extend ActiveSupport::Concern

  module ClassMethods
    def get_string(key, language)
      string = #{
        JSON::pretty_generate(strings.sort.to_h, allow_nan: true, max_nesting: false)
      }[key.to_sym]
      language = language.gsub(/[-_].*$/, '').to_sym
      string ? (string[language] || string[:en]) : string
    end
  end
end
}
o.close
