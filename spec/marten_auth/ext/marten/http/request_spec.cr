require "./spec_helper"

describe Marten::HTTP::Request do
  describe "#user" do
    it "returns the user associated with the user_id" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user_id = user.id.to_s

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash
      request.session = session_store

      request.user.should eq user
    end

    it "returns nil if the user_id does not correspond to any existing user" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user_id = "-1"

      request.user.should be_nil
    end

    it "returns nil and invalidates the session if the password changed since last session" do
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
      request.user_id = user.id.to_s
      request.session = session_store

      request.user.should be_nil
      request.session.session_key.should be_nil
    end

    it "returns nil if no user_id is associated with the request" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )

      request.user.should be_nil
    end
  end

  describe "#user?" do
    it "returns true if a user is authenticated" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user_id = user.id.to_s

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash
      request.session = session_store

      request.user?.should be_true
    end

    it "returns false if no user is authenticated" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )

      request.user?.should be_false
    end
  end

  describe "#user=" do
    it "allows to associate a new user record to the request" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user = user

      request.user.should eq user
      request.user_id.should eq user.pk.to_s
    end
  end

  describe "#user_id" do
    it "returns the authenticated user ID" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user_id = user.id.to_s

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash
      request.session = session_store

      request.user_id.should eq user.id.to_s
    end

    it "returns nil if no user ID is associated with the request" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )

      request.user_id.should be_nil
    end
  end

  describe "#user_id" do
    it "associates a user ID with the request" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user_id = user.id.to_s

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash
      request.session = session_store

      request.user_id.should eq user.id.to_s
    end

    it "resets the previously associated user record if one was set" do
      user_1 = create_user(email: "test1@example.com", password: "insecure")
      user_2 = create_user(email: "test2@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.user = user_1

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user_1.pk.to_s
      session_store["_auth_user_hash"] = user_1.session_auth_hash
      request.session = session_store

      request.user_id = user_2.pk.to_s
      session_store["_auth_user_hash"] = user_2.session_auth_hash

      request.user.should eq user_2
    end
  end
end
