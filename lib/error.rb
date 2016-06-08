module Now

  # The main exception class for NOW.
  class NowError < StandardError
    attr_accessor :code, :message

    def initialize(code, message)
      @code = code
      @message = message
    end

  end

end
