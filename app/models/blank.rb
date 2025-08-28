class Blank < Media
  validates_absence_of :quote, :url, :file

  def media_type
    'blank'
  end

  def class_name
    'Blank'
  end
end
