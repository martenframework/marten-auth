require "./ext/**"
require "./middleware"
require "./models/**"
require "./settings"

module MartenAuth
  class App < Marten::App
    label "marten_auth"
  end
end
