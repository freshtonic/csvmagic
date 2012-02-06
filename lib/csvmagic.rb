require 'trollop'
require 'pry'
require 'csv'
require 'ruby2ruby'
require 'ruby_parser'

module CSVMagic
  class Command
    def self.run
      opts = Trollop::options do

        version "csvmagic #{CSVMagic::VERSION::STRING} (c) 2012 James Sadler"
        banner <<-EOS

        CSVMagic is a program for manipulating CSV files.  It can filter,
        transform, and select arbitrary columns to generate a new file.

        Transformations, selectors and filters can be arbitrary Ruby code.  Why?
        Because awk and grep on CSVs sucks for anything beyond trivial!  (And we
        love Ruby).
        
        CSVMagic defines some variables which can be used within your Ruby
        expressions.

        $row_num (the current row number, minus blank lines and the header row
        if present)

        $line_num (the line number of the current row in the source file)

        (mostly $row_num is the same as $line_num, but $row_num is logical and
        has meaning even if a quoted column spans more than one line)

        <ruby_identifier> can be used to refer to the name of a column

        Usage:
              csvmagic [options] <filenames>+

        or when reading from STDIN

              csvmagic [options]

        where [options] are:
        EOS


        opt :where,

          Command.nice("Any rows matching this Ruby expression will be included in the
          output"), 
          
          :type => String

        opt :project, 
          
          Command.nice("Comma-seperated list of columns to output. Each item in the list is
          a Ruby expression"), 
          
          :type => String

      end

      Munger.new(opts, ARGV[0]).process

    end

    def self.nice(s)
      s.gsub(/[ \t\n]+/, ' ')
    end
  end

end
