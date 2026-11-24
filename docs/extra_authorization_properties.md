# Extra authorization properties

By default, the `odoo_member` authorization only stores the Odoo partner reference. You can store other
properties returned by the Odoo partner API, and allow admins to filter permissions by them, with an initializer
(e.g. `config/initializers/decidim_odoo.rb`):

```ruby
Decidim::Odoo.configure do |config|
  config.extra_authorization_properties = [:signature_delegated]
  config.extra_authorization_options = { signature_delegated: :boolean }
end
```

- `extra_authorization_properties`: Odoo partner properties stored in the authorization metadata.
- `extra_authorization_options`: properties that admins can use as options when configuring permissions, with
  their type.

The properties are updated every time the user is synchronized with Odoo.

Properties with the `:boolean` type are shown as a checkbox in the permissions form. When it is checked, only
users whose property is `true` are allowed to perform the action. Any other type is compared with the exact
value, as Decidim does by default.
