require 'roar/logger'

class LoggerTest < MiniTest::Spec
  before do
    @roar = Module.new
    @roar.extend Roar::Logger
  end

  describe "Roar.logger" do
    it "returns a instance of Logger" do
      assert_equal Logger, @roar.logger.class
    end
  end

  describe "Roar.logger=" do
    it "set a Logger to @@logger" do
      @roar.logger = "Logger"
      assert_equal "Logger", @roar.logger
    end
  end
end
