module TiplineNewsletterMutations
  fields = {
    introduction: 'str',
    rss_feed_url: 'str',
    first_article: 'str',
    second_article: 'str',
    third_article: 'str',
    number_of_articles: 'int',
    send_every: 'str',
    timezone: 'str',
    time: 'str',
    language: 'str'
  }

  Create, Update, Destroy = GraphqlCrudOperations.define_crud_operations('tipline_newsletter', create_fields, update_fields, ['tipline_newsletter'])
end
