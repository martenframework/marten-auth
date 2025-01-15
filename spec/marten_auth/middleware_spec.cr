require "./spec_helper"

describe MartenAuth::Middleware do
  describe "#call" do
    it "associates the current user ID from the session to the request" do
      user = User.new(email: "test@example.com")
      user.set_password("insecure")
      user.save!

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store

      middleware = MartenAuth::Middleware.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.user_id.should eq user.pk.to_s
      request.user.should eq user
    end

    it "invalidates the session if the password changed since last session" do
      user = User.new(email: "test@example.com")
      user.set_password("insecure")
      user.save!

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash

      user.set_password("other-insecure")
      user.save!

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store

      middleware = MartenAuth::Middleware.new
      middleware.call(
        request,
        -> { Marten::HTTP::Response.new("It works!", content_type: "text/plain", status: 200) }
      )

      request.user.should be_nil
      request.session.session_key.should be_nil
    end
  end
end
