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
          out << output
        end
      end

    end

    private

    # Compile the select expression to a lambda that when passed
    # the row object will return an array with the new row.
    def compile_select
      parser = RubyParser.new
      r2r = Ruby2Ruby.new
      sexp = parser.process("[#{@opts.expression}]")
      twiddled_sexp = BindToRowProcessor.new.process(sexp)
      ruby = r2r.process(twiddled_sexp)
      binding.pry
      eval "proc { #{ruby} }"
    end
  end

  class BindToRowProcessor < SexpProcessor
    def initialize
      super
    end

    def process_call(exp)
      binding.pry
      call = exp.shift
      target = exp.shift
      symbol = exp.shift
      arglist = exp.shift

      new_sexp = if target.nil?
        if arglist.size == 1
          # Try to resolve this as a column name.
          # If the column does not exist, then execute as Ruby method call.
          code = <<-RUBY
            if self.headers.include? '#{symbol}'
              self['#{symbol}']
            else
              #{symbol}
            end
          RUBY
          RubyParser.new.process(code)
        else
          process s(:call, nil, symbol, arglist)
        end
      elsif target[0] == :call
        s(:call, process(s(:call, target[1], target[2], target[3])), symbol, arglist) 
      else
        process s(:call, target, symbol, arglist)
      end
    end
  end
end
