module CSVMagic

  class Munger

    # opts is Trollop options object
    # extra_args is the remaining command line argumets (files probably)
    def initialize(opts, file)
      @opts = opts
      if file
        @input = File.open(file, 'r') 
      else
        @input = STDIN
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

    # Compile the select expression to a lambda that when passed
    # the row object will return an array with the new row.
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

  class ExpressionCompiler < SexpProcessor
    attr_accessor :headers

    def initialize
      super
      @parser = RubyParser.new
    end

    def process_call(exp)
      call = exp.shift
      target = exp.shift
      symbol = exp.shift
      arglist = exp.shift

      if target.nil?
        if arglist.size == 1
          # TODO: compile this statically.
          # Currently this generates the code that makes the check
          # on every row we visit. If we defer compilation until we
          # have the headers, we can bypass the check.
          if @headers.include? symbol.to_s 
            @parser.process("self['#{symbol}']")
          else
            @parser.process(symbol.to_s)
          end
        else
          process s(:call, nil, symbol, arglist)
        end
      elsif target[0] == :call
        s(:call, process(target), symbol, arglist) 
      else
        # Nothing to do here, anything else we leave as-is.
        # (the null transformation)
        s(:call, target, symbol, arglist)
      end
    end
  end
end
