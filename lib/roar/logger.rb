module Roar
  module Logger
    def logger
      @@logger ||= begin
        require "logger"
        ::Logger.new STDOUT
      end
    end

    def logger= logger
      @@logger = logger
    end
  end
end
