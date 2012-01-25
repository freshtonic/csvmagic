require 'trollop'

module CSVMagic
  class Command
    def self.run
      opts = Trollop::options do
        version "csvmagic #{CSVMagic::VERSION::STRING} (c) 2011 James Sadler"
        banner <<-EOS
        CSVMagic is a program for manipulating CSV files.
        It can filter, transform, and select arbitrary columns to generate a new 
        file. Transformations, selectors and filters can be arbitrary Ruby code.
        Why? Because awk and grep on CSVs sucks for anything beyond trivial!
        (And we love Ruby).
        
        CSVMagic defines some variables which can be used within your Ruby expressions.
          $row_num (the current row number, minus blank lines and the header row if present)
          $line_num (the line number of the current row in the source file)
            (mostly $row_num is the same as $line_num, but $row_num is logical and has meaning even if a quoted column spans more than one line)
          <ruby_identifier> can be used to refer to the name of a column



        Usage:
              csvmagic [options] <filenames>+
        or when reading from STDIN
              csvmagic [options]

        where [options] are:
        EOS

        opt :exclude, "Any rows matching this Ruby expression will be excluded from the output. Can be specified multiple times and will be ORed together. (cannot use --include with --exclude).", :type => String, :multi => true
        opt :include, "Any rows not matching this Ruby expression will be excluded from the output. Can be specified multiple times and will be ORed together. (cannot use --include with --exclude). ", :type => String, :multi => true
        opt :save_excluded, "Any rows excluded from the output will be saved to the file. The row will be preserved in its original form", :type => String
        opt :select, "Comma-seperated list of columns to output. Each item in the list is a Ruby expression", :type => String
        opt :in_place, "Modify the input file in place. WARNING: this operation is destrcutive! (Does not apply when reading from STDIN)", :default => false
        opt :header, "Treat the first line of the CSV file as a header that contains the column names. You can now refer to columns by name in your expressions", :default => false
        opt :headings, "Tells CSVMagic what the column names are so you can use the names in your expressions. Not necessary if you use the --header option", :type => String
        opt :output_header, "Output the column names for all selected columns", :default => false
        opt :input_encoding, "The input encoding, e.g. ascii, UTF-8", :type => String
        opt :output_encoding, "The output encoding, e.g. ascii, UTF-8", :type => String
        opt :input_delimiter, "Column delimiter for the input", :type => String, :default => ','
        opt :output_delimiter, "Column delimiter for the output", :type => String, :default => ','
        opt :input_quotechar, "Input quote character", :type => String, :default => '"'
        opt :output_quotechar, "Output quote character", :type => String, :default => '"'
        opt :require, "Ruby files to require before processing. This enables the use of custom Ruby code to be called during expression evaluation. This option can be used multiple times", :type => String, :multi => true
        opt :eval, "Ruby code to be evaluated before processing. Use this option to specify methods inline to be called during expression evaluation. This option can be used multiple times", :type => String, :multi => true

      end
      
      Trollop::die :exclude, "--exclude cannot be used with --include" if opts[:include] && opts[:exclude]
      Trollop::die :header, "--header cannot be used with --headings" if opts[:header] && opts[:headings]

    end
  end
end
