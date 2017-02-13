class SingletonAnnotationBase < ActiveRecord::Base
  include AnnotationBase

  def destroy
    # should revert singleton annotation
    widget = self.paper_trail.previous_version
    if widget.nil?
      # delete annotation if no versions
      Annotation.find(self.id).destroy
    else
      widget.paper_trail.without_versioning do
        widget.save!
        self.versions.last.destroy
      end
    end
  end

  def get_versions
    an = [self]
    versions = self.versions.to_a
    versions.each do |obj|
      an << obj.reify unless obj.reify.nil?
    end
    an
  end

  private

  def set_annotator
    self.annotator = User.current unless User.current.nil?
  end

end
