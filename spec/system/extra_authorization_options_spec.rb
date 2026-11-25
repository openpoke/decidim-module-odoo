# frozen_string_literal: true

require "spec_helper"
require "decidim/blogs/test/factories"

describe "Extra_authorization_options" do
  let(:organization) { create(:organization, available_authorizations: ["odoo_member"]) }
  let(:participatory_space) { create(:participatory_process, :with_steps, organization:) }
  let(:component) { create(:post_component, participatory_space:) }
  let!(:post) { create(:post, :published, component:) }
  let!(:original_manifest) { Decidim::Verifications.find_workflow_manifest(:odoo_member) }

  around do |example|
    previous_backend = I18n.backend
    I18n.backend = I18n::Backend::Simple.new
    example.run
    I18n.backend = previous_backend
  end

  before do
    I18n.backend.store_translations(
      :en,
      decidim: { authorization_handlers: { odoo_member: { fields: { signature_delegated: "Signature delegated" } } } }
    )
    allow(Decidim::Odoo).to receive(:extra_authorization_options).and_return(signature_delegated: :boolean)
    Decidim::Verifications.unregister_workflow(original_manifest)
    Decidim::Odoo::Engine.initializers.find { |initializer| initializer.name == "decidim_odoo.authorizations" }.run
    switch_to_host(organization.host)
    login_as user, scope: :user
  end

  after do
    manifest = Decidim::Verifications.find_workflow_manifest(:odoo_member)
    Decidim::Verifications.reset_workflows(*(Decidim::Verifications.workflow_collection.to_a - [manifest]), original_manifest)
  end

  context "when an admin configures the permissions" do
    let(:user) { create(:user, :admin, :confirmed, organization:) }

    before do
      visit Decidim::EngineRouter.admin_proxy(participatory_space).edit_component_permissions_path(
        component.id,
        resource_name: post.resource_manifest.name,
        resource_id: post.id
      )
    end

    it "saves the extra authorization option" do
      within "#components form" do
        within ".comment-permission" do
          expect(page).to have_content("Odoo Membership")
          check "Odoo Membership"
          expect(page).to have_content("Signature delegated")
          check "Signature delegated"
        end
        find("*[type=submit]").click
      end

      expect(page).to have_content("Permissions updated successfully.")
      expect(post.reload.permissions["comment"]).to eq(
        "authorization_handlers" => {
          "odoo_member" => { "options" => { "signature_delegated" => "1" } }
        }
      )
    end
  end

  context "when a user visits a restricted resource" do
    let(:user) { create(:user, :confirmed, organization:) }
    let(:signature_delegated) { true }

    before do
      post.create_resource_permission(
        permissions: {
          "comment" => {
            "authorization_handlers" => {
              "odoo_member" => { "options" => { "signature_delegated" => "1" } }
            }
          }
        }
      )
      create(:authorization, name: "odoo_member", user:, metadata: { signature_delegated: })
      visit Decidim::ResourceLocatorPresenter.new(post).path
    end

    context "when the user has the property" do
      it "can comment" do
        expect(page).to have_css("#add-comment-anchor")
      end
    end

    context "when the user does not have the property" do
      let(:signature_delegated) { false }

      it "cannot comment" do
        expect(page).to have_no_css("#add-comment-anchor")
        expect(page).to have_content("You need to be verified to comment at this moment")
      end
    end
  end
end
