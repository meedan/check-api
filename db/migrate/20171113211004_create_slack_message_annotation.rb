class CreateSlackMessageAnnotation < ActiveRecord::Migration[4.2]
  require 'sample_data'
  include SampleData

  def change
    create_annotation_type_and_fields('Slack Message', { 'Id' => ['Id', false], 'Attachments' => ['JSON', false] })
  end
end
