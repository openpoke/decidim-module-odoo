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

The properties are not updated in real time. They are only refreshed when the user is synchronized with Odoo
(when the user signs in with Odoo, from the Odoo members page in the admin or with
`bin/rails decidim:odoo:sync:members`), and the authorization is updated afterwards in a background job.
Until then, permissions use the previous value, so if a property is used to restrict access, consider running
the synchronization task periodically. Failed updates are logged by `AutoVerificationJob`.

Existing authorizations do not include the new properties until their users are synchronized again. Before
enabling a restriction in the permissions form, synchronize the existing members, either with
`bin/rails decidim:odoo:sync:members` or from the Odoo members page in the admin, and wait for the
background jobs to finish. Otherwise, users with outdated authorizations will not be allowed to perform the action.

Properties with the `:boolean` type are shown as a checkbox in the permissions form. When it is checked, only
users whose property is `true` are allowed to perform the action. Any other type is compared with the exact
value, as Decidim does by default.
