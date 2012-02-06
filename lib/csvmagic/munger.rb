module CSVMagic

  class Munger

    # opts is Trollop options object
    # extra_args is the remaining command line argumets (files probably)
    def initialize(opts, file)
      @opts = opts
      @input = if file
        File.open(file, 'r') 
      else
        STDIN
      end
      @output = STDOUT
    end

    def process
      options = {
        :headers => :first_row, 
        :return_headers => false,
        :row_sep => :auto
      }

      CSV(@output) do |out|
        CSV.new(@input, options).each do |row|
          @select ||= compile_select(row.headers)
          output = row.instance_eval(&@select)
          out << output
        end
      end

    end

    private

    def compile_select(headers)
      parser = RubyParser.new
      r2r = Ruby2Ruby.new
      sexp = parser.process("[#{@opts.expression}]")
      compiler = ExpressionCompiler.new
      compiler.headers = headers
      twiddled_sexp = compiler.process(sexp)
      ruby = r2r.process(twiddled_sexp)
      eval "proc { #{ruby} }"
    end
  end

  # Rewites :call sexps so that anything that looks like a variable lookup or
  # a method with no arguments will be re-written to look-up the value from
  # a column with that heading name.
  #
  # Anything else will be evaluated as a normal Ruby call.
  #
  # The 'is this a column heading?' check happens once only and is compiled away
  # (when we have the headings from the CSV file).
  #
  class ExpressionCompiler < SexpProcessor
    attr_accessor :headers

    def initialize
      super
      @parser = RubyParser.new
    end

    def headers=(val)
      @headers = val
      @cleaned_headers = cleanup_headings
    end

    def process_call(exp)
      call = exp.shift
      target = exp.shift
      symbol = exp.shift
      arglist = exp.shift

      if target.nil?
        if arglist.size == 1
          if @cleaned_headers.include? symbol.to_s
            heading = @headers[@cleaned_headers.index(symbol.to_s)]
            @parser.process("self['#{heading}']")
          else
            @parser.process(symbol.to_s)
          end
        else
          process s(:call, nil, symbol, arglist)
        end
      elsif target[0] == :call
        s(:call, process(target), symbol, arglist) 
      else
        # Pass anything else through untouched and don't process any further.
        s(:call, target, symbol, arglist)
      end
    end

    private

    def cleanup_headings
      @headers.map do |h|
        h.gsub(/[^a-zA-Z0-0_\!\?]/, "_")
      end
    end
  end
end
