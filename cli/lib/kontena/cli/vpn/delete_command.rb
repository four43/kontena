module Kontena::Cli::Vpn
  class DeleteCommand < Clamp::Command
    include Kontena::Cli::Common

    def execute
      require_api_url
      token = require_token

      vpn = client(token).get("services/#{current_grid}/vpn") rescue nil
      abort("VPN service does not exist") if vpn.nil?

      client(token).delete("services/#{current_grid}/vpn")
    end
  end
end
