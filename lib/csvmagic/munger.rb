module CSVMagic
  class Munger

    # opts is Trollop options object
    # extra_args is the remaining command line argumets (files probably)
    def initialize(opts, extra_args)
      @opts = opts
      @files = open_files(extra_args)
    end

    def process
      # consume the CSV file with faster csv (just read it all into memory for
      # now.
      @csvs = @files.inject({}) do |hash,f|
        content = FasterCSV.parse(f)
        @headings ||= headings(content)
        hash[File.basename(f.path)] = content
        hash
      end

      FasterCSV(STDOUT) do |csv|
        if @opts.headings
          csv << @headings if @headings
        end
        @csvs.each_pair do |name,content|
          content.each do |line|
            csv << line
          end
        end
      end
    end

    private

    def open_files(files)
      @files = files.map do |file|
        File.open(File.expand_path(".", file))
      end
    end

    def headings(content)
      if @opts.headings
        @opts.headings.split(",").map(&:to_sym)
      elsif @opts.header
        content.shift
        content[0].map(&:to_sym) if content.size > 0
      else
        []
      end
    end

  end

end
