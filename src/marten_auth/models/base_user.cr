module MartenAuth
  abstract class BaseUser < Marten::Model
    def self.get_by_natural_key(natural_key) : BaseUser
      raise NotImplementedError.new("#get_by_natural_key must be implemented by subclasses")
    end

    def self.get_by_natural_key!(natural_key) : BaseUser
      raise NotImplementedError.new("#get_by_natural_key! must be implemented by subclasses")
    end

    abstract def check_password(raw_password : String) : Bool
    abstract def set_password(raw_password : String) : Nil
    abstract def session_auth_hash : String
  end
end
