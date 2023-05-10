class MockedClamavClient
  def initialize(response_type)
    @response_type = response_type
  end

  def execute(_input)
    if @response_type == 'virus'
      ClamAV::VirusResponse.new(nil, nil)
    else
      ClamAV::SuccessResponse.new(nil)
    end
  end
end
