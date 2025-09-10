# frozen_string_literal: true

namespace :decidim do
  namespace :odoo do
    desc "Fix users nickname"
    task :fix_nicknames, [:dry_run] => :environment do |_t, args|
      dry_run = args[:dry_run].to_s == "dry_run"

      vat_regex = '^[a-zA-Z]{2,3}\d{8,12}[a-zA-Z]?$'
      users = Decidim::User.where("nickname ~ '#{vat_regex}'")

      puts "There are a total of #{users.count} users that are going to be treated"
      puts "Dry run:" if dry_run

      count = 0
      users.each do |user|
        old_nickname = user.nickname
        new_nickname = Decidim::UserBaseEntity.nicknamize(user.name, user.decidim_organization_id)

        if dry_run
          puts "#{old_nickname} will be updated to #{new_nickname}"
          count += 1
        elsif user.update(nickname: new_nickname)
          puts "#{old_nickname} updated to #{new_nickname}"
          count += 1
        end
      end

      puts "Total of #{count} users updated." unless dry_run
      puts "Dry run complete. Total of #{count} would be updated" if dry_run
    end
  end
end
