
require 'csvmagic/types'

module CSVMagic

  class Munger

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
          @select ||= compile_project(row.headers)
          @where  ||= compile_where(row.headers)
          output = row.instance_eval(&@select) if row.instance_eval(&@where)
          out << output if output
        end
      end

    end

    private

    def compile_project(headers)
      compile(headers, "[#{@opts.project}]")
    end

    def compile_where(headers)
      compile(headers, "#{@opts.where || 'true'}")
    end

    def compile(headers, prog)
      parser = RubyParser.new
      r2r = Ruby2Ruby.new
      sexp = parser.process(prog)
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
            @parser.process("parse_value(self['#{heading}'])")
          else
            @parser.process(symbol.to_s)
          end
        else
          s(:call, 
            nil, 
            symbol.is_a?(Sexp) ? process(symbol) : symbol, 
            arglist.is_a?(Sexp) ? process(arglist) : arglist)
        end
      else
        s(:call, 
          target.is_a?(Sexp) ? process(target) : target,
          symbol.is_a?(Sexp) ? process(symbol) : symbol,
          arglist.is_a?(Sexp) ? process(arglist) : arglist)
      end
    end

    private

    def cleanup_headings
      @headers.map do |h|
        h.gsub(/[^a-zA-Z0-0_\!\?]/, "_")
      end
    end
  end

  class CSV::Row
    # The user-supplied expressions are evaluated with  an instance of CSV::Row
    # as self. The following code puts the value parser in the same context.
    include Types 
  end
end
