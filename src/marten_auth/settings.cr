module MartenAuth
  # Holds auth-related settings.
  class Settings < Marten::Conf::Settings
    namespace :auth

    @password_reset_token_expiry_time : Time::Span = Time::Span.new(days: 3)
    @user_model : MartenAuth::BaseUser.class | Nil

    # Returns the expiry time for password reset tokens.
    getter password_reset_token_expiry_time

    # Allows to set the expiry time for password reset tokens.
    setter password_reset_token_expiry_time

    # Allows to set the user model class that should be used for authentication purposes.
    setter user_model

    # Returns the user model class that should be used for authentication purposes.
    #
    # If no user model is configured, a `Marten::Conf::Errors::InvalidConfiguration` exception will be raised.
    def user_model : MartenAuth::BaseUser.class
      @user_model || raise Marten::Conf::Errors::InvalidConfiguration.new(
        "A user model must be configured in the auth.user_model setting"
      )
    end
  end
end
