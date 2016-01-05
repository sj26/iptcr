require "iptcr"
require "iptcr/records"

module IPTCR
  # # IPTC
  #
  # ## Notes
  #
  # IPTC metadata is a series of records. Records contain datasets. Each
  # dataset contains a data field, which is a particular value for that
  # dataset. Repeated datasets represent mulitple fields for the same dataset,
  # like for list data.
  #
  # ## References
  #
  # * https://www.iptc.org/std/photometadata/2008/specification/IPTC-PhotoMetadata-2008.pdf
  # * https://www.iptc.org/std/IIM/4.1/specification/IIMV4.1.pdf
  # * https://en.wikipedia.org/wiki/ISO/IEC_2022#ISO.2FIEC_2022_character_sets
  class IPTC
    attr_reader :fields

    # IPTC IIM specifics the default encoding is ISO646/4873, which is roughly ASCII
    DEFAULT_ENCODING = Encoding::ASCII

    def initialize(io, length:)
      @fields = []
      read_fields(io, length: length)
    end

    def encoding
      @encoding || DEFAULT_ENCODING
    end

    def [](name)
      field_values[name]
    end

    def to_hash
      field_values
    end

    private

    def read_fields(io, length:)
      unless length.nil?
        start = io.tell
        finish = start + length
      end

      until io.eof? || (!length.nil? && io.tell >= finish)
        read_field(io)
      end
    end

    MARKER = 0x1c

    def read_field(io)
      marker = io.getbyte
      unless marker == MARKER
        raise Malformed, "Expected marker byte, got: #{marker}"
      end

      record_number = io.getbyte

      dataset_number = io.getbyte

      # Length can be a variable integer
      length = io.read(2).unpack("S>").first
      if length & 0x8000 == 0x8000
        size = length & 0x7fff
        length = 0
        size.times do
          length = (length << 8) + io.readbyte
        end
      end

      start = io.tell
      finish = start + length

      field = Field.new(record_number: record_number, dataset_number: dataset_number, data: io.read(length), encoding: encoding)
      @fields << field

      # IPTC specifies that records must be ordered. This dataset is in the
      # first possible record, so later records (like the main application
      # record) should all receive this encoding.
      #
      # There is a list of encodings here:
      # https://en.wikipedia.org/wiki/ISO/IEC_2022#ISO.2FIEC_2022_character_sets
      #
      # Ruby doesn't support a bunch of them, so we really only support UTF-8
      # and fall back to ASCII.
      if field.dataset? and field.dataset_name == "CodedCharacterSet"
        case field.value
        when "\x1b%G"
          @encoding = Encoding::UTF_8
        else
          EXIFR.logger.warn { "IPTC: Unknown codec character set: #{field.value.inspect}" }
        end
      end

      unless io.tell == finish
        io.seek(finish)
      end
    end

    def field_values
      @field_values ||= @fields.each_with_object({}) do |field, index|
        if field.dataset?
          if field.dataset[:list]
            (index[field.dataset_name] ||= []) << field.value
          else
            index[field.dataset_name] = field.value
          end
        end
      end
    end

    class Field
      def initialize(record_number:, dataset_number:, data:, encoding:)
        @record_number = record_number
        @dataset_number = dataset_number
        @data = data
        @encoding = encoding
      end

      attr_reader :record_number

      def record?
        RECORDS.has_key? record_number
      end

      def record
        RECORDS[record_number]
      end

      def record_name
        if record?
          record[:name]
        end
      end

      attr_reader :dataset_number, :data

      def dataset?
        if record?
          record[:datasets] && record[:datasets].has_key?(dataset_number)
        end
      end

      def dataset
        if dataset?
          record[:datasets][dataset_number]
        end
      end

      def dataset_name
        if dataset?
          dataset[:name]
        end
      end

      def dataset_type
        if dataset?
          dataset[:type]
        end
      end

      attr_reader :data

      attr_reader :encoding

      def value
        case dataset_type
        when "string"
          # Record number 1 is always the default encoding
          if record_number == 1
            @data.force_encoding(DEFAULT_ENCODING)
          # Records 2-6 and 8 respect tagged encoding
          elsif (2..6).include?(record_number) || record_number == 8
            @data.force_encoding(encoding)
          # Other behaviour is undefined
          else
            @data
          end
        when "digits"
          @data
        when "int8u"
          @data.unpack("C").first
        when "int16u"
          @data.unpack("S").first
        when "int32u"
          @data.unpack("L").first
        else
          @data
        end
      end

      def inspect
        "#<%s:0x%014x record=%s dataset=%s %p>" % [self.class, object_id, inspect_record, inspect_dataset, value]
      end

      private def inspect_record
        if record?
          record_name
        else
          "unknown:0x%x" % [record_number]
        end
      end

      private def inspect_dataset
        if dataset?
          dataset_name
        else
          "unknown:0x%x" % [dataset_number]
        end
      end
    end
  end
end
