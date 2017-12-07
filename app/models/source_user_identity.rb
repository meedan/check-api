require 'active_support/concern'

module SourceUserIdentity
  extend ActiveSupport::Concern
  included do
    attr_accessor :identity

    def identity=(info)
	    info = info.blank? ? {} : JSON.parse(info)
	    unless info.blank?
	    	si = self.class.name == 'User' ? get_user_identity : get_team_source_identity
	      info.each{ |k, v| si.send("#{k}=", v) if si.respond_to?(k) and !v.blank? }
	      si.save!
	    end
	  end

	  def identity
	    data = {}
	    attributes = %W(name bio file)
	    si = get_source_annotations('source_identity')
	    attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) } unless si.nil?
	    if self.class.name == 'TeamSource'
	    	si = get_annotations('source_identity').last
	    	attributes.each{|k| ks = k.to_s; data[ks] = si.send(ks) unless si.send(ks).nil? } unless si.nil?
	  	end
	    data
	  end

	  private

	  def get_user_identity
	  	si = get_source_annotations('source_identity')
	  	si.nil? ? create_new_identity(self.source) : si.load
	  end

	  def get_team_source_identity
	  	si = get_annotations('source_identity').last
	  	si.nil? ? create_new_identity(self) : si.load
	  end

	  def create_new_identity(annotated)
	  	si = SourceIdentity.new
	    si.annotated = annotated
	    si.annotator = User.current unless User.current.nil?
	    si
	  end

	  def get_source_annotations(type = nil)
	  	self.source.annotations.where(annotation_type: type).last
  	end

  end
end