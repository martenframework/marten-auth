class Marten::HTTP::Request
  @user : Bool | MartenAuth::BaseUser | Nil
  @user_id : String?

  # Returns the current user ID associated with the considered request, or `nil` if there is no authenticated user.
  getter user_id

  # Returns the user associated with the request, or `nil` if there is no authenticated user.
  def user : MartenAuth::BaseUser?
    user_id.nil? ? nil : (@user ||= fetch_user).as?(MartenAuth::BaseUser)
  end

  # Returns the user associated with the request, or raise `NilAssertionError` if there is no authenticated user.
  def user! : MartenAuth::BaseUser
    user.not_nil!
  end

  # Returns `true` if a user is authenticated for the request.
  def user? : Bool
    !user.nil?
  end

  # Allows to set the current user ID for the request.
  def user=(user : MartenAuth::BaseUser?) : Nil
    @user_id = user.try(&.pk.to_s)
    @user = user
  end

  # Allows to set the current user ID for the request.
  def user_id=(user_id : String?) : Nil
    @user = nil
    @user_id = user_id
  end

  private NO_USER = true

  private def fetch_user
    fetched_user = Marten.settings.auth.user_model.get(pk: user_id)
    return NO_USER if fetched_user.nil?

    if !MartenAuth.valid_session_hash?(self, fetched_user)
      session.flush
      fetched_user = NO_USER
    end

    fetched_user
  end
end
