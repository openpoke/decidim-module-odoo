# frozen_string_literal: true

require "omniauth/strategies/odoo_keycloak"

module Decidim
  module Odoo
    # This is the engine that runs on the public interface of odoo.
    class Engine < ::Rails::Engine
      isolate_namespace Decidim::Odoo

      config.to_prepare do
        Decidim::User.include(Decidim::Odoo::UserOverride)
        # omniauth only trigger notifications when a new user is registered
        # this adds a notification too when user logs in
        Decidim::CreateOmniauthRegistration.include(Decidim::Odoo::CreateOmniauthRegistrationOverride)
      end

      initializer "decidim_odoo.omniauth" do
        next unless Decidim::Odoo.keycloak_omniauth && Decidim::Odoo.keycloak_omniauth[:client_id]

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider :odoo_keycloak, Decidim::Odoo.keycloak_omniauth[:client_id], Decidim::Odoo.keycloak_omniauth[:client_secret],
                   client_options: Decidim::Odoo.keycloak_omniauth[:client_options]
        end
      end

      initializer "decidim_odoo.user_sync" do
        ActiveSupport::Notifications.subscribe "decidim.user.omniauth_registration" do |_name, data|
          Decidim::Odoo::OmniauthUserSyncJob.perform_later(data) if data[:provider] == Decidim::Odoo::OMNIAUTH_PROVIDER_NAME
        end
        ActiveSupport::Notifications.subscribe "decidim.odoo.user.updated" do |_name, data|
          Decidim::Odoo::AutoVerificationJob.perform_later(data)
        end
      end

      initializer "decidim_odoo.authorizations" do
        next unless Decidim::Odoo.authorizations

        if Decidim::Odoo.authorizations.include?(:odoo_member)
          Decidim::Verifications.register_workflow(:odoo_member) do |workflow|
            workflow.form = "Decidim::Odoo::Verifications::OdooMember"
          end
        end
      end

      initializer "decidim_odoo.webpacker.assets_path" do
        Decidim.register_assets_path File.expand_path("app/packs", root)
      end
    end
  end
end
