# frozen_string_literal: true

require "spec_helper"

module Decidim::Odoo::Verifications
  describe OdooMemberActionAuthorizer do
    subject { described_class.new(authorization, options, component, nil).authorize }

    let(:organization) { create(:organization) }
    let(:user) { create(:user, :confirmed, organization:) }
    let(:component) { create(:dummy_component, organization:) }
    let(:metadata) { { signature_delegated: true } }
    let(:authorization) { create(:authorization, name: "odoo_member", user:, metadata:) }
    let(:options) { { "signature_delegated" => "1" } }
    let(:extra_authorization_options) { { signature_delegated: :boolean } }

    before do
      allow(Decidim::Odoo).to receive(:extra_authorization_options).and_return(extra_authorization_options)
    end

    context "when the option is checked and the metadata is true" do
      it { is_expected.to eq([:ok, {}]) }
    end

    context "when the option is checked and the metadata is false" do
      let(:metadata) { { signature_delegated: false } }

      it { is_expected.to eq([:unauthorized, { fields: ["signature_delegated"] }]) }
    end

    context "when the option is checked and the metadata does not have the property" do
      let(:metadata) { {} }

      it { is_expected.to eq([:unauthorized, { fields: ["signature_delegated"] }]) }
    end

    context "when the option is unchecked" do
      let(:options) { { "signature_delegated" => "0" } }
      let(:metadata) { { signature_delegated: false } }

      it { is_expected.to eq([:ok, {}]) }
    end

    context "when there are no options" do
      let(:options) { {} }
      let(:metadata) { {} }

      it { is_expected.to eq([:ok, {}]) }
    end

    context "when the property is not configured as a boolean option" do
      let(:extra_authorization_options) { {} }
      let(:metadata) { { signature_delegated: false } }

      it "leaves it to the default authorizer" do
        expect(subject).to eq([:unauthorized, { fields: { "signature_delegated" => "1" } }])
      end
    end

    context "when there is no authorization" do
      let(:authorization) { nil }

      it { is_expected.to eq([:missing, { action: :authorize }]) }
    end

    context "when the authorization is pending" do
      let(:authorization) { create(:authorization, :pending, name: "odoo_member", user:, metadata:) }

      it { is_expected.to eq([:pending, { action: :resume }]) }
    end
  end
end
