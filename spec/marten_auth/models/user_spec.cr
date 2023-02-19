require "./spec_helper"

describe MartenAuth::User do
  describe "::get_by_natural_key" do
    it "returns the user record corresponding to the passed email address" do
      user = create_user(email: "test@example.com", password: "insecure")
      User.get_by_natural_key("test@example.com").should eq user
    end

    it "returns nil if no user record is associated with the passed email address" do
      User.get_by_natural_key("unknown@example.com").should be_nil
    end
  end

  describe "::get_by_natural_key!" do
    it "returns the user record corresponding to the passed email address" do
      user = create_user(email: "test@example.com", password: "insecure")
      User.get_by_natural_key!("test@example.com").should eq user
    end

    it "raises if no user record is associated with the passed email address" do
      expect_raises(Marten::DB::Errors::RecordNotFound) { User.get_by_natural_key!("unknown@example.com") }
    end
  end

  describe "#check_password" do
    it "returns false if the user has no password set" do
      user = User.new(email: "test@example.com", password: nil)
      user.check_password("pwd").should be_false
    end

    it "returns true if the passed password corresponds to the password that was encrypted for the user" do
      user = create_user(email: "test@example.com", password: "insecure")
      user.check_password("insecure").should be_true
    end

    it "returns false if the passed password does not correspond to the password that was encrypted for the user" do
      user = create_user(email: "test@example.com", password: "insecure")
      user.check_password("otherpwd").should be_false
    end

    it "returns false if the user has a badly encoded password" do
      user = User.create!(email: "test@example.com", password: "notset")

      user.check_password("notset").should be_false
    end
  end

  describe "#set_password" do
    it "allows to set the password of a user without password" do
      user = User.new(email: "test@example.com", password: nil)
      user.set_password("insecure")
      user.check_password("insecure").should be_true
    end

    it "allows to set the password of a user with an existing password" do
      user = create_user(email: "test@example.com", password: "insecure")
      user.set_password("newpassword")
      user.check_password("insecure").should be_false
      user.check_password("newpassword").should be_true
    end
  end

  describe "#session_auth_hash" do
    it "it returns the expected HMAC computed from the password" do
      user = create_user(email: "test@example.com", password: "insecure")

      key_salt = "MartenAuth::User#session_auth_hash"
      key_digest = OpenSSL::Digest.new("SHA256")
      key_digest.update(key_salt + Marten.settings.secret_key)
      key = key_digest.hexfinal
      expected_session_auth_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, key, user.password!)

      user.session_auth_hash.should eq expected_session_auth_hash
    end

    it "it changes for each password value as expected" do
      user = create_user(email: "test@example.com", password: "insecure")

      key_salt = "MartenAuth::User#session_auth_hash"
      key_digest = OpenSSL::Digest.new("SHA256")
      key_digest.update(key_salt + Marten.settings.secret_key)
      key = key_digest.hexfinal
      first_expected_session_auth_hash = OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, key, user.password!)

      user.session_auth_hash.should eq first_expected_session_auth_hash

      user.set_password("newpassword")

      user.session_auth_hash.should_not eq first_expected_session_auth_hash
    end
  end
end
