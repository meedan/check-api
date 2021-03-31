class ApiConstraints
  def initialize(options)
    @version = options[:version]
    @default = options[:default]
  end

  def matches?(req)
    @default || req.headers['Accept'].to_s.include?(ApiConstraints.accept(@version))
  end

  def self.accept(version = 1)
    version == 1 ? 'application/vnd.lapis.v1' : 'application/vnd.api+json'
  end
end
