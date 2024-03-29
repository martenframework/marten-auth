require "./base_user"

module MartenAuth
  # Main abstract user model.
  #
  # This method defines a common abstract user model with the following fields:
  #
  # * `id` (big int)
  # * `email` (email)
  # * `password` (string)
  # * `created_at` (date time)
  # * `updated_at` (date time)
  #
  # This abstract user model is intended to be subclassed in projects that wish to implement an authentication mechanism
  # based on generic user properties (email, password).
  abstract class User < BaseUser
    field :id, :big_int, primary_key: true, auto: true
    field :email, :email, unique: true
    field :password, :string, max_size: 128
    field :created_at, :date_time, auto_now_add: true
    field :updated_at, :date_time, auto_now: true

    def self.get_by_natural_key(natural_key) : BaseUser?
      get(email: natural_key)
    end

    def self.get_by_natural_key!(natural_key) : BaseUser
      get!(email: natural_key)
    end

    # Returns `true` if the passed raw password matches the encrypted user password.
    def check_password(raw_password : String) : Bool
      return false if password.nil?

      Crypto::Bcrypt::Password.new(password!).verify(raw_password)
    rescue Crypto::Bcrypt::Error
      false
    end

    # Allows to set and encrypt a new user password.
    def set_password(raw_password : String) : Nil
      self.password = Crypto::Bcrypt::Password.create(raw_password).to_s
    end

    # Allows to assign a non-usable password to the user.
    #
    # The assigned value is not a valid hash and will never be usable by the user.
    def set_unusable_password : Nil
      self.password = String.build do |s|
        s << UNUSABLE_PASSWORD_PREFIX
        s << Random::Secure.random_bytes((UNUSABLE_PASSWORD_SUFFIX_LENGTH / 2).to_i).hexstring
      end
    end

    # Returns the authentication hash (HMAC computed from the password) that should be embedded in sessions.
    def session_auth_hash : String
      key_salt = "MartenAuth::User#session_auth_hash"
      key_digest = OpenSSL::Digest.new("SHA256")
      key_digest.update(key_salt + Marten.settings.secret_key)
      key = key_digest.hexfinal

      OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, key, password!)
    end

    private UNUSABLE_PASSWORD_PREFIX        = "!" # This ensures that the password will never be a valid encoded hash.
    private UNUSABLE_PASSWORD_SUFFIX_LENGTH = 40
  end
end
