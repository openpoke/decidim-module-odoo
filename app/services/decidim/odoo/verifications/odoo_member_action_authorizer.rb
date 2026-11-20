# frozen_string_literal: true

module Decidim
  module Odoo
    module Verifications
      class OdooMemberActionAuthorizer < Decidim::Verifications::DefaultActionAuthorizer
        def authorize
          @required_boolean_options ||= extract_required_boolean_options

          status_code, data = *super
          return [status_code, data] unless status_code == :ok
          return [:unauthorized, { fields: unmet_boolean_options }] if unmet_boolean_options.any?

          [status_code, data]
        end

        private

        def extract_required_boolean_options
          boolean_options.select { |property| cast_boolean(options.delete(property)) }
        end

        def boolean_options
          Decidim::Odoo.extra_authorization_options.select { |_, type| type == :boolean }.keys.map(&:to_s)
        end

        def unmet_boolean_options
          @unmet_boolean_options ||= @required_boolean_options.reject { |property| cast_boolean(authorization.metadata[property]) }
        end

        def cast_boolean(value)
          ActiveModel::Type::Boolean.new.cast(value)
        end
      end
    end
  end
end
