# This class tries to reproduce an ActiveRecord relation
class ElasticsearchRelation
  def initialize(params = {})
    @params = params
  end

  def offset(x)
    @params[:from] = x
    @params[:size] ||= 10
    self
  end

  def limit(x)
    @params[:size] = x
    self
  end

  def all
    Annotation.search(@params).results.map(&:load).reject{ |x| x.nil? }
  end

  def count
    Annotation.search(@params.merge({ size: 0 })).total
  end

  def to_a
    all
  end
end
