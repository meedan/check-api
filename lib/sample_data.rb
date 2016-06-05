module SampleData
  
  # Methods to generate random data

  def random_string(length = 10)
    (0...length).map{ (65 + rand(26)).chr }.join
  end

  def random_email
    random_string + '@' + random_string + '.xyz'
  end

  def random_number(max = 50)
    rand(max) + 1
  end

  def create_api_key(options = {})
    ApiKey.create! options
  end
end
