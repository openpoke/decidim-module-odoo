# frozen_string_literal: true

require "spec_helper"

module Decidim
  describe CreateOmniauthRegistration do
    describe "call" do
      let(:organization) { create(:organization) }
      let(:email) { "user@from-odoo.com" }
      let(:provider) { "odoo_keycloak" }
      let(:uid) { "12345" }
      let(:oauth_signature) { OmniauthRegistrationForm.create_signature(provider, uid) }
      let(:verified_email) { email }
      let(:tos_agreement) { true }
      let(:nickname) { "odoo_user" }
      let(:form_params) do
        {
          "user" => {
            "provider" => provider,
            "uid" => uid,
            "email" => email,
            "email_verified" => true,
            "name" => "Odoo User",
            "nickname" => nickname,
            "oauth_signature" => oauth_signature,
            "avatar_url" => "http://www.example.com/foo.jpg",
            "tos_agreement" => tos_agreement
          }
        }
      end
      let(:form) do
        OmniauthRegistrationForm.from_params(
          form_params
        ).with_context(
          current_organization: organization
        )
      end
      let(:command) { described_class.new(form, verified_email) }

      before do
        stub_request(:get, "http://www.example.com/foo.jpg")
          .to_return(status: 200, body: File.read("spec/assets/avatar.jpg"), headers: { "Content-Type" => "image/jpeg" })
      end

      it "broadcasts ok" do
        expect { command.call }.to broadcast(:ok)
      end

      it "creates a new user" do
        allow(SecureRandom).to receive(:hex).and_return("decidim123456789")

        expect do
          command.call
        end.to change(User, :count).by(1)

        user = User.find_by(email: form.email)
        expect(user.encrypted_password).not_to be_nil
        expect(user.email).to eq(form.email)
        expect(user.organization).to eq(organization)
        expect(user.newsletter_notifications_at).to be_nil
        expect(user).to be_confirmed
        expect(user.valid_password?("decidim123456789")).to be(true)
      end

      # NOTE: This is important so that the users who are only
      # authenticating using omniauth will not need to update their
      # passwords.
      it "leaves password_updated_at nil" do
        expect { command.call }.to broadcast(:ok)

        user = User.find_by(email: form.email)
        expect(user.password_updated_at).to be_nil
      end

      it "notifies about registration with oauth data" do
        user = create(:user, email:, organization:)
        identity = Decidim::Identity.new(id: 1234)
        allow(command).to receive(:create_identity).and_return(identity)

        expect(ActiveSupport::Notifications)
          .to receive(:publish)
          .with("decidim.events.core.welcome_notification",
                affected_users: [user],
                event_class: "Decidim::WelcomeNotificationEvent",
                extra: { :force_email => true },
                followers: [],
                force_send: false,
                resource: user)

        expect(ActiveSupport::Notifications)
          .to receive(:publish)
          .with(
            "decidim.user.omniauth_registration",
            user_id: user.id,
            identity_id: 1234,
            provider:,
            uid:,
            email:,
            name: "Odoo User",
            nickname: "odoo_user",
            avatar_url: "http://www.example.com/foo.jpg",
            raw_data: {},
            tos_agreement: true,
            accepted_tos_version: user.accepted_tos_version,
            newsletter_notifications_at: user.newsletter_notifications_at

          )
        command.call
      end

      context "when identity already exists" do
        let!(:user) { create(:user, email:, organization:) }
        let!(:identity) { create(:identity, provider:, uid:, user:) }

        it "notifies about registration with existing identity" do
          expect(ActiveSupport::Notifications)
            .to receive(:publish)
            .with(
              "decidim.user.omniauth_registration",
              user_id: user.id,
              identity_id: identity.id,
              provider:,
              uid:,
              email:,
              name: "Odoo User",
              nickname: "odoo_user",
              avatar_url: "http://www.example.com/foo.jpg",
              raw_data: {},
              tos_agreement: true,
              accepted_tos_version: user.accepted_tos_version,
              newsletter_notifications_at: user.newsletter_notifications_at
            )
          command.call
        end
      end
    end
  end
end
