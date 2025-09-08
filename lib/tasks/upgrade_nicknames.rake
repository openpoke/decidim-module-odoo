# frozen_string_literal

namespace :decidim do
  namespace :odoo do
    desc "Fix users nickname"
    task fix_nicknames: :environment do
      vat_regex = '^[a-zA-Z]{2}\d{8,12}[a-zA-Z]?$'
      users = Decidim::User.where("nickname ~ '#{vat_regex}'")

      puts "There are a total of #{users.count} users that are going to be updated"

      count = 0
      users.each do |user|
        user.nickname = Decidim::UserBaseEntity.nicknamize(user.name, user.decidim_organization_id)
        user.save!
        count += 1
      end

      puts "Total of #{count} users updated."
    end
  end
end
