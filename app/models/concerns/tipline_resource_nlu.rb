require 'active_support/concern'

module TiplineResourceNlu
  extend ActiveSupport::Concern

  ALEGRE_CONTEXT_KEY_RESOURCE = 'smooch_nlu_resource'

  def keywords=(_value)
    raise "Don't set keywords directly! Use methods add_keyword and remove_keyword instead."
  end

  def add_keyword(keyword)
    update_resource_keywords(keyword, 'add')
  end

  def remove_keyword(keyword)
    update_resource_keywords(keyword, 'remove')
  end

  private

  def update_resource_keywords(keyword, operation)
    keywords = self.keywords
    doc_id = Digest::MD5.hexdigest([ALEGRE_CONTEXT_KEY_RESOURCE, self.team.slug, self.id, keyword].join(':'))
    context = {
      context: ALEGRE_CONTEXT_KEY_RESOURCE,
      resource_id: self.id
    }
    nlu = SmoochNlu.new(self.team.slug)
    new_keywords = nlu.update_keywords(self.language, keywords, keyword, operation, doc_id, context)
    self.update_column(:keywords, new_keywords)
  end

  module ClassMethods
    def resource_from_message(message, language, uid)
      context = {
        context: ALEGRE_CONTEXT_KEY_RESOURCE
      }
      matches = SmoochNlu.alegre_matches_from_message(message, language, context, 'resource_id', uid).collect{ |m| m['key'] }
      # Select the top resource that exists
      resource_id = matches.find { |id| TiplineResource.where(id: id).exists? }
      Rails.logger.info("[Smooch NLU] [Resource From Message] Resource ID: #{resource_id} | Message: #{message}")
      TiplineResource.find_by_id(resource_id.to_i)
    end
  end
end
