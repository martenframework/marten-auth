class AuthRespondHandler < Marten::Handler
  def dispatch
    respond request.user? ? "authenticated with user ##{request.user!.pk}" : "anonymous"
  end
end
