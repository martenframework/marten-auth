class Marten::Spec::Client
  def sign_in(user : MartenAuth::BaseUser) : Nil
    session["_auth_user_pk"] = user.pk.to_s
    session["_auth_user_hash"] = user.session_auth_hash
  end

  def sign_out : Nil
    session.flush
  end
end
