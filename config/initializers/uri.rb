require 'uri'

module URI
  
  # We need to also support "track" and "id" from Media Fragments 1.0 URI Advanced (https://www.w3.org/TR/media-frags/#mf-advanced)
  FRAGMENT_NAMES = ['t', 'xywh']

  def media_fragment
    URI.media_fragment(self.fragment)
  end

  def self.media_fragment(fragment_string)
    fragment = {}
    fragment_string.split('&').each do |nv|
      name, value = nv.split('=')
      if FRAGMENT_NAMES.include?(name)
        fragment_value = self.send("parse_fragment_#{name}", value)
        fragment[name] = fragment_value unless fragment_value.blank?
      else
        Rails.logger.warn "Warning, name #{name} was ignored because it is not a valid media fragment (basic) as per https://www.w3.org/TR/media-frags - it should be one of #{FRAGMENT_NAMES.join(', ')}"
      end
    end
    fragment.with_indifferent_access
  end

  def self.parse_fragment_t(value)
    m = value.match(/^([a-z]+:)?(.*)$/)
    return nil if m.nil?
    interval = []
    if m[1].nil? || m[1] == 'npt:'
      start, finish = m[2].split(',')
      start = '0.0' if start.blank?
      [start, finish].each do |time|
        if time.to_s =~ /^(([0-9]+)|([0-9]+\.[0-9]+)|([0-9]+:[0-9]+:[0-9]+)|([0-9]+:[0-9]+:[0-9]+\.[0-9]+))$/
          interval << time.split(':').map { |a| a.to_f }.inject(0) { |a, b| a * 60 + b }
        end
      end
    else
      Rails.logger.warn "Warning, for now temporal clipping can only be specified as Normal Play Time (npt)"
    end
    interval
  end

  def self.parse_fragment_xywh(value)
    m = value.match(/^(([a-z]+):)?([0-9]+,[0-9]+,[0-9]+,[0-9]+)$/)
    return nil if m.nil?
    space = {}
    unit = m[2] || 'pixel'
    if ['pixel', 'percent'].include?(unit)
      x, y, w, h = m[3].split(',').map(&:to_i)
      space = { 'x' => x, 'y' => y, 'width' => w, 'height' => h, 'unit' => unit }
    else
      Rails.logger.warn "Warning, for now a spatial clipping can only be specified as pixel or percent"
    end
    space
  end
end
