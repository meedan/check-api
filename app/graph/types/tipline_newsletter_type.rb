class TiplineNewsletterType < DefaultObject
  description "TiplineNewsletter type"

  implements NodeIdentification.interface

  field :dbid, Integer, null: true
  field :introduction, String, null: true
  field :header_type, String, null: true
  field :header_file_url, String, null: true
  field :header_overlay_text, String, null: true
  field :content_type, String, null: true
  field :rss_feed_url, String, null: true
  field :first_article, String, null: true
  field :second_article, String, null: true
  field :third_article, String, null: true
  field :number_of_articles, Integer, null: true
  field :send_every, JsonString, null: true
  field :send_on, String, null: true

  def send_on
    object.send_on ? object.send_on.strftime("%Y-%m-%d") : nil
  end
  field :timezone, String, null: true
  field :time, String, null: true

  def time
    object.time.strftime("%H:%M")
  end
  field :subscribers_count, Integer, null: true
  field :footer, String, null: true
  field :language, String, null: true
  field :enabled, Boolean, null: true
  field :team, TeamType, null: true
  field :last_scheduled_at, Integer, null: true
  field :last_scheduled_by, UserType, null: true
  field :last_sent_at, Integer, null: true
  field :last_delivery_error, String, null: true
end
