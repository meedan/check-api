module TiplineNewsletterMutations
  fields = {
    enabled: 'bool',
    introduction: 'str',
    language: 'str'
  }

  # Header
  fields.merge!({
    header_type: 'str',
    header_overlay_text: 'str'
  })

  # Content
  fields.merge!({
    content_type: 'str'
  })

  # Dynamic newsletter: RSS Feed
  fields.merge!({
    rss_feed_url: 'str',
    number_of_articles: 'int'
  })

  # Static newsletter: Articles
  fields.merge!({
    first_article: 'str',
    second_article: 'str',
    third_article: 'str'
  })

  # Footer
  fields.merge!({
    footer: 'str'
  })

  # Schedule
  fields.merge!({
    send_every: 'json',
    send_on: 'str',
    timezone: 'str',
    time: 'str'
  })

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tipline_newsletter', fields, fields, ['team'])
end
