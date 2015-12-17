# IPTCR

[![Build Status](https://travis-ci.org/sj26/iptcr?branch=master)](https://travis-ci.org/sj26/iptcr)

IPTC Reader in Ruby. Parse IPTC data extracted from an image into rich data types and respecting string encodings.

## Usage

Use something like imagemagick to extract the IPTC, then read it with this class:

```ruby
require "iptcr"
raw_iptc = `convert images/ian.jpg iptc:-`
iptc = IPTCR.parse(iptc)
iptc["ObjectName"] # => "Ian"
iptc.to_hash # => {"ObjectName" => "Ian", "ColorSequence" => 32, ...}
```

## Thanks

Inspired by [ExifTool][exiftool].

  [exiftool]: http://www.sno.phy.queensu.ca/~phil/exiftool/

## License

MIT license, see [LICENSE](LICENSE).
