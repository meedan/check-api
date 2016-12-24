require 'active_support/concern'

module MediaInformation
  extend ActiveSupport::Concern

  def set_information
    info = self.parse_information
    unless self.information_blank?
      em = get_embed(self)
      em = set_information_for_context if em.nil?
      self.set_information_for_embed(em, info)
      self.information = {}.to_json
    end
  end

  protected

  def parse_information
    self.information.blank? ? {} : JSON.parse(self.information)
  end

  def information_blank?
    self.parse_information.all? { |_k, v| v.blank? }
  end

  def get_embed(obj)
    Embed.where(annotation_type: 'embed', annotated_type: obj.class.to_s , annotated_id: obj.id).last
  end

  def set_information_for_context
    em_none = get_embed(self.media)
    if em_none.nil?
      em = Embed.new
      em.embed = self.information
    else
      # clone existing one and reset annotator fields
      em = em_none.dup
      em.annotator_id = em.annotator_type = nil
    end
    em.annotated = self
    em.annotator = self.current_user unless self.current_user.nil?
    em
  end

  def set_information_for_embed(em, info)
    info.each{ |k, v| em.send("#{k}=", v) if em.respond_to?(k) and !v.blank? }
    em.save!
  end
end
