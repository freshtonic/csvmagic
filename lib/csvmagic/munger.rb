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

      select = compile_select

      CSV(@output) do |out|
        CSV.new(@input, options).each do |row|
          output = row.instance_eval(&select)
          out << output #.to_csv
        end
      end

    end

    private

    # Compile the select expression to a lambda that when passed
    # the row object will return an array with the new row.
    def compile_select
      #eval("proc { [#{@opts.expression}] }") 
      parser = RubyParser.new
      r2r = Ruby2Ruby.new
      sexp = parser.process("[#{@opts.expression}]")
      twiddled_sexp = BindToRowProcessor.new.process(sexp)
      ruby = r2r.process(twiddled_sexp)
      eval "proc { #{ruby} }"
    end
  end

  class BindToRowProcessor < SexpProcessor
    def initialize
      super
    end

    def process_call(exp)
      call = exp.shift
      unknown = exp.shift
      symbol = exp.shift
      arglist = exp.shift
      code = <<-RUBY
        if headers.include?('#{symbol}')
          self['#{symbol}']
        else
          #{symbol}
        end
      RUBY
      new_sexp = RubyParser.new.process(code)
      new_sexp
    end
  end
end
