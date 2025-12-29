module MartenAuth
  # The authentication middleware.
  #
  # This middleware ensures that the currently authenticated user ID is associated to the current request. This ensures
  # that this user can be easily retrieved later on.
  class Middleware < Marten::Middleware
    def call(request : Marten::HTTP::Request, get_response : Proc(Marten::HTTP::Response)) : Marten::HTTP::Response
      request.user_id = MartenAuth.get_user_session_key(request)
      get_response.call
    end
  end
end
