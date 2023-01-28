require "./spec_helper"

describe Marten::Spec::Client do
  describe "#sign_in" do
    it "signs in a user as expected" do
      user = create_user(email: "test@example.com", password: "insecure")

      Marten::Spec.client.sign_in(user)

      response = Marten::Spec.client.get(Marten.routes.reverse("auth_respond"))

      response.content.should eq "authenticated with user ##{user.id}"
    end
  end

  describe "#sign_out" do
    it "signout out a user as expected" do
      user = create_user(email: "test@example.com", password: "insecure")

      Marten::Spec.client.sign_in(user)
      Marten::Spec.client.sign_out

      response = Marten::Spec.client.get(Marten.routes.reverse("auth_respond"))

      response.content.should eq "anonymous"
    end
  end
end
