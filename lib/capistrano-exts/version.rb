module Capistrano
  module Extensions
    module Version #:nodoc:
      MAJOR = 1
      MINOR = 1
      TINY = 4

      ARRAY  = [MAJOR, MINOR, TINY]
      STRING = ARRAY.join(".")
    end
  end
end
