require "crypto/bcrypt/password"

require "./marten_auth/app"

module MartenAuth
  VERSION = "0.1.0"

  @@password_reset_token_encryptor : Marten::Core::Encryptor?

  # Tries to authenticate the user associated identified by `natural_key` and check that the given `password` is valid.
  #
  # This method verifies that the passed credentials (user `natural_key` and `password`) are valid and returns the
  # corresponding user record if that's the case. Otherwise the method returns `nil` if the credentials can't be
  # verified because the user does not exist or because the password is invalid.
  #
  # It is important to realize that this method _only_ verifies user credentials and does not sign in users for a
  # specific request. Signing in users is handled by the `#sign_in` method.
  def self.authenticate(natural_key : String, password : String) : BaseUser?
    user = Marten.settings.auth.user_model.get_by_natural_key!(natural_key)
    return user if user.check_password(password)
  rescue Marten::DB::Errors::RecordNotFound
  end

  # Returns a valid, encrypted, and expirable password reset token for the passed user.
  def self.generate_password_reset_token(user : BaseUser) : String
    password_reset_token_encryptor.encrypt(
      {
        PASSWORD_RESET_TOKEN_USER_PK_KEY  => user.pk.to_s,
        PASSWORD_RESET_TOKEN_PASSWORD_KEY => user.password,
      }.to_json,
      expires: Time.local + Marten.settings.auth.password_reset_token_expiry_time
    )
  end

  # Returns the current user ID as a string, extracted from the passed `request` session.
  def self.get_user_session_key(request : Marten::HTTP::Request) : String?
    request.session[USER_PK_SESSION_KEY]?
  end

  # Signs in a user for the specified request.
  #
  # This method ensures that the user ID is persisted in the request and the associated session so that they do not have
  # to reauthenticate for every request.
  #
  # It is important to understand that this method is intended to be used for a user record whose credentials were
  # validated using the `#authenticate` method beforehand.
  def self.sign_in(request : Marten::HTTP::Request, user : BaseUser)
    session_auth_hash = user.session_auth_hash

    if request.session[USER_PK_SESSION_KEY]?
      if get_user_session_key(request) != user.pk.to_s || (session_auth_hash && !valid_session_hash?(request, user))
        request.session.flush
      end
    else
      request.session.cycle_key
    end

    request.session[USER_PK_SESSION_KEY] = user.pk.to_s
    request.session[USER_HASH_SESSION_KEY] = session_auth_hash
    request.user = user

    # Sets the CSRF cookie to nil to force it to be rotated with the new login.
    request.cookies[Marten.settings.csrf.cookie_name] = nil
  end

  # Signs out the current user.
  #
  # Removes the authenticated user ID from the current request and flushes the associated session data.
  def self.sign_out(request : Marten::HTTP::Request) : Nil
    request.session.flush
    request.user = nil
  end

  # Returns a boolean indicating if the passed password reset token is valid for the considered `user`.
  def self.valid_password_reset_token?(user : BaseUser, token : String) : Bool
    decrypted = Hash(String, String).from_json(password_reset_token_encryptor.decrypt!(token))

    (
      Crypto::Subtle.constant_time_compare(decrypted[PASSWORD_RESET_TOKEN_USER_PK_KEY], user.pk.to_s) &&
        Crypto::Subtle.constant_time_compare(decrypted[PASSWORD_RESET_TOKEN_PASSWORD_KEY], user.password!)
    )
  rescue JSON::ParseException | Marten::Core::Encryptor::InvalidValueError
    false
  end

  # Returns a boolean indicating if the authentication hash in the session corresponds to the passed `user`'s one.
  def self.valid_session_hash?(request, user)
    Crypto::Subtle.constant_time_compare(
      request.session[USER_HASH_SESSION_KEY]? || "",
      user.session_auth_hash
    )
  end

  private PASSWORD_RESET_TOKEN_PASSWORD_KEY = "password"
  private PASSWORD_RESET_TOKEN_USER_PK_KEY  = "user_pk"
  private USER_HASH_SESSION_KEY             = "_auth_user_hash"
  private USER_PK_SESSION_KEY               = "_auth_user_pk"

  private def self.password_reset_token_encryptor
    @@password_reset_token_encryptor ||= Marten::Core::Encryptor.new(
      key: "marten_auth/password_reset_token/" + Marten.settings.secret_key
    )
  end
end
