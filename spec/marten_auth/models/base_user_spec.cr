require "./spec_helper"

describe MartenAuth::BaseUser do
  describe "::get_by_natural_key" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError, "#get_by_natural_key must be implemented by subclasses") do
        MartenAuth::BaseUser.get_by_natural_key("test@example.com")
      end
    end
  end

  describe "::get_by_natural_key!" do
    it "raises NotImplementedError" do
      expect_raises(NotImplementedError, "#get_by_natural_key! must be implemented by subclasses") do
        MartenAuth::BaseUser.get_by_natural_key!("test@example.com")
      end
    end
  end
end
