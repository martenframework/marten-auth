require "./base_user"

module MartenAuth
  abstract class User < BaseUser
    field :id, :big_int, primary_key: true, auto: true
    field :email, :email
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
    end

    # Allows to set and encrypt a new user password.
    def set_password(raw_password : String) : Nil
      self.password = Crypto::Bcrypt::Password.create(raw_password).to_s
    end

    # Returns the authentication hash (HMAC computed from the password) that should be embedded in sessions.
    def session_auth_hash : String
      key_salt = "MartenAuth::User#session_auth_hash"
      key_digest = OpenSSL::Digest.new("SHA256")
      key_digest.update(key_salt + Marten.settings.secret_key)
      key = key_digest.hexfinal

      OpenSSL::HMAC.hexdigest(OpenSSL::Algorithm::SHA256, key, password!)
    end
  end
end
