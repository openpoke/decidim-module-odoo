# frozen_string_literal: true

require "decidim/odoo/admin"
require "decidim/odoo/admin_engine"
require "decidim/odoo/api"
require "decidim/odoo/engine"

module Decidim
  # This namespace holds the logic of the `Odoo` component. This component
  # allows users to create odoo in a participatory space.
  module Odoo
    include ActiveSupport::Configurable

    OMNIAUTH_PROVIDER_NAME = "odoo_keycloak"

    config_accessor :api do
      {
        base_url: ENV.fetch("ODOO_API_BASE_URL", nil),
        api_key: ENV.fetch("ODOO_API_API_KEY", nil)
      }
    end

    config_accessor :keycloak_omniauth do
      {
        enabled: ENV["OMNIAUTH_ODOO_KEYCLOAK_CLIENT_ID"].present?,
        client_id: ENV["OMNIAUTH_ODOO_KEYCLOAK_CLIENT_ID"].presence,
        client_secret: ENV["OMNIAUTH_ODOO_KEYCLOAK_CLIENT_SECRET"].presence,
        site: ENV["OMNIAUTH_ODOO_KEYCLOAK_SITE"].presence,
        realm: ENV.fetch("OMNIAUTH_ODOO_KEYCLOAK_REALM", "opencell"),
        icon_path: ENV.fetch("OMNIAUTH_ODOO_KEYCLOAK_ICON_PATH", "media/images/odoo_logo.png")
      }
    end

    config_accessor :authorizations do
      [:odoo_member]
    end

    class Error < StandardError; end
  end
end
