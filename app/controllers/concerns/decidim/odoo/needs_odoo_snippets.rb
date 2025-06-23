# frozen_string_literal: true

module Decidim
  module Odoo
    module NeedsOdooSnippets
      extend ActiveSupport::Concern

      included do
        helper_method :snippets
      end

      def snippets
        @snippets ||= Decidim::Snippets.new

        unless @snippets.any?(:oauth2_odoo)
          @snippets.add(:oauth2_odoo, ActionController::Base.helpers.stylesheet_pack_tag("decidim_odoo"))
          @snippets.add(:head, @snippets.for(:oauth2_odoo))
        end

        @snippets
      end
    end
  end
end
