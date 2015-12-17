require "iptcr/version"

module IPTCR
  def self.parse(value, length: nil)
    if value.is_a? String
      require "stringio"
      length ||= value.bytesize
      IPTC.new(StringIO.new(value), length: length)
    else
      IPTC.new(value, length: length)
    end
  end

  autoload :IPTC, "iptcr/iptc"
end
