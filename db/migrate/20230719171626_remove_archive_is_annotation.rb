class RemoveArchiveIsAnnotation < ActiveRecord::Migration[6.1]
  def change
    # We no longer use archive_is. This has been run manually on QA and Live,
    # so is mostly intended to make sure that we don't generate an outdated schema
    # when running bin/rails lapis:graphql:schema locally from new database
    archive_is = DynamicAnnotation::AnnotationType.where(annotation_type: 'archive_is')
    archive_is.delete_all if archive_is.any?
  end
end
