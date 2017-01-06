require 'active_support/concern'

module MediaInformation
  extend ActiveSupport::Concern

  def set_information
    info = self.parse_information
    unless self.information_blank?
      em_context = self.get_embed_context
      em_none = self.get_embed_regardless_context

      em = if em_context.nil? and em_none.nil?
             self.set_information_for_context(em_none)
           elsif self.project.nil?
             self.set_information_for_context(em_none)
           else
             self.set_information_for_context_with_no_pender(em_context, em_none)
           end
      self.set_information_for_embed(em, info)
      self.information = {}.to_json
    end
  end

  protected

  def information_blank?
    self.parse_information.all? { |_k, v| v.blank? }
  end

  def get_embed_context
    self.annotations('embed', self.project).last unless self.project.nil?
  end

  def get_embed_regardless_context
    self.annotations('embed', 'none').last
  end

  def parse_information
    info = self.information.blank? ? {} : JSON.parse(self.information)
    info[:title] = self.quote if self.url.nil? and info["title"].blank?
    self.information = info.to_json
    info
  end

  def set_information_for_context_with_no_pender(em_context, em_none)
    em = em_context unless em_context.nil?
    em.nil? ? set_information_for_context(em_none) : em
  end

  def set_information_for_context(em_none)
    em = em_none.nil? ? Embed.new : em_none
    if em_none.nil?
      em = Embed.new
      em.embed = self.information
      em.annotated = self
    else
      # clone existing one and reset annotator fields
      em = em_none.dup
      em.annotator_id = em.annotator_type = nil
    end
    em.annotator = User.current unless User.current.nil?
    em.context = self.project
    em
  end

  def set_information_for_embed(em, info)
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end
end
