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

      # controllers and helpers overrides
      initializer "decidim_odoo.overrides", after: "decidim.action_controller" do
        config.to_prepare do
          Decidim::Devise::SessionsController.include(Decidim::Odoo::NeedsOdooSnippets)
          Decidim::ApplicationController.include(Decidim::Odoo::NeedsOdooSnippets)
        end
      end

      initializer "decidim_odoo.omniauth" do
        next unless Decidim::Odoo.keycloak_omniauth && Decidim::Odoo.keycloak_omniauth[:enabled].present?

        # Decidim use the secrets configuration to decide whether to show the omniauth provider
        Rails.application.secrets[:omniauth][Decidim::Odoo::OMNIAUTH_PROVIDER_NAME.to_sym] = Decidim::Odoo.keycloak_omniauth
        # ensure external icon is available to avoid break the aplication (see the implementati0on of omniauth_helper.rb/oauth_icon)
        Decidim::Odoo.keycloak_omniauth[:icon_path] = "media/images/odoo_logo.png" if Decidim::Odoo.keycloak_omniauth[:icon_path].blank?

        Rails.application.config.middleware.use OmniAuth::Builder do
          provider :odoo_keycloak,
                   Decidim::Odoo.keycloak_omniauth[:client_id],
                   Decidim::Odoo.keycloak_omniauth[:client_secret],
                   site: Decidim::Odoo.keycloak_omniauth[:site],
                   icon_path: Decidim::Odoo.keycloak_omniauth[:icon_path],
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
