require "./spec_helper"

describe MartenAuth::Settings do
  describe "#password_reset_token_expiry_time" do
    it "returns the expected time span by default" do
      settings = MartenAuth::Settings.new
      settings.password_reset_token_expiry_time.should eq Time::Span.new(days: 3)
    end

    it "returns the configured time span" do
      settings = MartenAuth::Settings.new
      settings.password_reset_token_expiry_time = Time::Span.new(days: 10)
      settings.password_reset_token_expiry_time.should eq Time::Span.new(days: 10)
    end
  end

  describe "#password_reset_token_expiry_time=" do
    it "allows to set the configured time span" do
      settings = MartenAuth::Settings.new
      settings.password_reset_token_expiry_time = Time::Span.new(days: 10)
      settings.password_reset_token_expiry_time.should eq Time::Span.new(days: 10)
    end
  end

  describe "#user_model" do
    it "returns the configured user model" do
      settings = MartenAuth::Settings.new
      settings.user_model = User
      settings.user_model.should eq User
    end

    it "raises if no user model is configured" do
      settings = MartenAuth::Settings.new
      expect_raises(
        Marten::Conf::Errors::InvalidConfiguration,
        "A user model must be configured in the auth.user_model setting"
      ) do
        settings.user_model
      end
    end
  end
end
