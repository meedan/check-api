module TiplineNewsletterMutations
  fields = {
    enabled: 'bool',
    introduction: 'str',
    language: 'str',

    # Header
    header_type: 'str',
    header_overlay_text: 'str',

    # Dynamic newsletter: RSS Feed
    rss_feed_url: 'str',
    number_of_articles: 'int',

    # Static newsletter: Articles
    first_article: 'str',
    second_article: 'str',
    third_article: 'str',

    # Footer
    footer: 'str',

    # Schedule
    send_every: 'json',
    timezone: 'str',
    time: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tipline_newsletter', fields, fields, ['team'])
end
