require "iptcr/version"

module IPTCR
  class Malformed < RuntimeError; end

  def self.parse(value, length: nil, **kwargs)
    if value.is_a? String
      require "stringio"
      length ||= value.bytesize
      IPTC.new(StringIO.new(value), length: length, **kwargs)
    else
      IPTC.new(value, length: length, **kwargs)
    end
  end

  autoload :IPTC, "iptcr/iptc"
end
