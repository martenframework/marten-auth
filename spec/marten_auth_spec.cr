require "./spec_helper"

describe MartenAuth do
  describe "::authenticate" do
    it "returns the user corresponding with the passed natural key if the specified password matches" do
      user = create_user(email: "test@example.com", password: "insecure")

      MartenAuth.authenticate("test@example.com", "insecure").should eq user
    end

    it "returns nil if the specified password does not match the user password" do
      create_user(email: "test@example.com", password: "insecure")

      MartenAuth.authenticate("test@example.com", "badpassword").should be_nil
    end

    it "returns nil if the passed natural key does not correspond to any users" do
      MartenAuth.authenticate("unknown@example.com", "insecure").should be_nil
    end
  end

  describe "::generate_password_reset_token" do
    it "generates an encrypted token containing the expected user information" do
      user = create_user(email: "test@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user)

      verifier_encryptor = Marten::Core::Encryptor.new(
        key: "marten_auth/password_reset_token/" + Marten.settings.secret_key
      )

      decrypted = Hash(String, String).from_json(verifier_encryptor.decrypt!(token))
      decrypted["user_pk"].should eq user.pk.to_s
      decrypted["password"].should eq user.password.to_s
    end

    it "generates an expirable token with with the expected expiry time span" do
      user = create_user(email: "test@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user)

      verifier_encryptor = Marten::Core::Encryptor.new(
        key: "marten_auth/password_reset_token/" + Marten.settings.secret_key
      )

      Timecop.freeze(Time.local + Marten.settings.auth.password_reset_token_expiry_time + Time::Span.new(hours: 1)) do
        verifier_encryptor.decrypt(token).should be_nil
      end
    end
  end

  describe "::get_user_session_key" do
    it "extracts and returns the user session key from the passed request" do
      user = create_user(email: "test@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store

      MartenAuth.get_user_session_key(request).should eq user.pk.to_s
    end

    it "returns nil if no user session key is in the session" do
      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")

      MartenAuth.get_user_session_key(request).should be_nil
    end
  end

  describe "::sign_in" do
    it "signs in a user for a specific request" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")

      MartenAuth.sign_in(request, user)

      request.session["_auth_user_pk"].should eq user.pk.to_s
      request.session["_auth_user_hash"].should eq user.session_auth_hash
      request.user.should eq user
    end

    it "cycles the session key" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      request.session["foo"] = "bar"

      MartenAuth.sign_in(request, user)

      request.session.session_key.should be_nil
      request.session["foo"].should eq "bar"
    end

    it "resets the CSRF token in cookies to force it to be rotated upon login" do
      user = create_user(email: "test@example.com", password: "insecure")

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      request.cookies[Marten.settings.csrf.cookie_name] = "csrftoken"

      MartenAuth.sign_in(request, user)

      request.cookies[Marten.settings.csrf.cookie_name].should eq ""
    end

    it "flushes the session before authenticating a new user if another user was previously authenticated" do
      user_1 = create_user(email: "test1@example.com", password: "insecure")
      user_2 = create_user(email: "test2@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user_1.pk.to_s
      session_store["_auth_user_hash"] = user_1.session_auth_hash

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store
      request.user = user_1

      MartenAuth.sign_in(request, user_2)

      request.session.session_key.should be_nil
      request.session["_auth_user_pk"].should eq user_2.pk.to_s
      request.session["_auth_user_hash"].should eq user_2.session_auth_hash
      request.user.should eq user_2
    end

    it "flushes the session before authenticating the user if they were authenticated with an old session auth hash" do
      user = create_user(email: "test@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = "old"

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store

      MartenAuth.sign_in(request, user)

      request.session.session_key.should be_nil
      request.session["_auth_user_pk"].should eq user.pk.to_s
      request.session["_auth_user_hash"].should eq user.session_auth_hash
      request.user.should eq user
    end
  end

  describe "::sign_out" do
    it "flushes the session and resets any authenticated user" do
      user = create_user(email: "test@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store
      request.user = user

      MartenAuth.sign_out(request)

      request.session.session_key.should be_nil
      request.session.empty?.should be_true
      request.user.should be_nil
    end
  end

  describe "::valid_password_reset_token?" do
    it "returns true for a valid password reset token" do
      user = create_user(email: "test@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user)

      MartenAuth.valid_password_reset_token?(user, token).should be_true
    end

    it "returns false for an invalid password reset token" do
      user = create_user(email: "test@example.com", password: "insecure")

      MartenAuth.valid_password_reset_token?(user, "bad").should be_false
    end

    it "returns false if the password reset token was created for another user" do
      user_1 = create_user(email: "test1@example.com", password: "insecure")
      user_2 = create_user(email: "test2@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user_1)

      MartenAuth.valid_password_reset_token?(user_2, token).should be_false
    end

    it "returns false if the user password changed since the password reset token was generaated" do
      user = create_user(email: "test@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user)

      user.set_password("newpassword")
      user.save!

      MartenAuth.valid_password_reset_token?(user, token).should be_false
    end

    it "returns false if the password reset token has expired" do
      user = create_user(email: "test@example.com", password: "insecure")

      token = MartenAuth.generate_password_reset_token(user)

      Timecop.freeze(Time.local + Marten.settings.auth.password_reset_token_expiry_time + Time::Span.new(hours: 1)) do
        MartenAuth.valid_password_reset_token?(user, token).should be_false
      end
    end
  end

  describe "::valid_session_hash?" do
    it "returns true if the request's session auth hash matches the passed user one" do
      user = create_user(email: "test@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = user.session_auth_hash

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store
      request.user = user

      MartenAuth.valid_session_hash?(request, user).should be_true
    end

    it "returns false if the request's session auth hash matches the passed user one" do
      user = create_user(email: "test@example.com", password: "insecure")

      session_store = Marten::HTTP::Session::Store::Cookie.new("sessionkey")
      session_store["_auth_user_pk"] = user.pk.to_s
      session_store["_auth_user_hash"] = "bad"

      request = Marten::HTTP::Request.new(
        method: "GET",
        resource: "/test/xyz",
        headers: HTTP::Headers{"Host" => "example.com"},
      )
      request.session = session_store
      request.user = user

      MartenAuth.valid_session_hash?(request, user).should be_false
    end
  end
end
