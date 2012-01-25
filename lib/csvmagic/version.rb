# -*- encoding: utf-8 -*-
module CSVMagic # :nodoc:
  module VERSION # :nodoc:
    unless defined? MAJOR
      MAJOR  = 0 
      MINOR  = 0
      TINY   = 1
      PRE    = nil

      STRING = [MAJOR, MINOR, TINY, PRE].compact.join('.')

      SUMMARY = "csvmagic #{STRING}"
    end
  end
end

