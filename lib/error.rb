module Now
  # The main exception class for NOW.
  class NowError < StandardError
    attr_accessor :code

    def initialize(code)
      @code = code
    end
  end
end
