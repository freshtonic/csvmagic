module CSVMagic
  module Types

    TYPES = [
      { match: /^[-+]?\d+$/,                       parser: lambda{|s| s.to_i } },
      { match: /^[-+]?\d*\.?\d+([eE][-+]?\d+)?$/,  parser: lambda{|s| s.to_f } },
      { match: /^\d{4}\/\d{2}\/\d{2}$/,            parser: lambda{|s| Date.strptime s, '%Y/%m/%d' } }
    ] 

    UNMATCHED_PARSER = lambda{|s| s == "" ? nil : s }

    def parse_value(str)
      type = TYPES.detect do |type|
        str =~ type[:match] 
      end || { parser: UNMATCHED_PARSER }
      type[:parser].call(str)
    end
  end
end
