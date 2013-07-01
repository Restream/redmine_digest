namespace :redmine_digest do

  desc 'Send daily digests by all active rules'
  task :send_daily => [:environment] do
    puts "#{Time.now} Send daily digests."
    send_digests DigestRule.active.daily
  end

  desc 'Send weekly digests by all active rules'
  task :send_weekly => [:environment] do
    puts "#{Time.now} Send weekly digests."
    send_digests DigestRule.active.weekly
  end

  desc 'Send monthly digests by all active rules'
  task :send_monthly => [:environment] do
    puts "#{Time.now} Send monthly digests."
    send_digests DigestRule.active.monthly
  end

  def send_digests(rules)
    rules_count = rules.count
    puts "#{Time.now} Found #{rules_count} rules."
    rules.each_with_index do |rule, idx|
      send_digest_by_rule(rule, "#{idx + 1} / #{rules_count}")
    end
  end

  def send_digest_by_rule(rule, npp)
    puts "#{Time.now} #{npp} Sending #{rule.recurrent} digest [#{rule.id}] to #{rule.user.mail} <#{rule.user.login}>"

    digest = RedmineDigest::Digest.new(rule)
    if digest.issues.any?
      DigestMailer.with_synched_deliveries do
        DigestMailer.digest_email(digest).deliver
      end
      puts "#{Time.now} Done. Digest contains #{digest.issues.count} issues."
    else
      puts "#{Time.now} Done. Digest empty and was not sent."
    end

  rescue StandardError => e
    $stderr.puts "#{Time.now} Failed to send digest with error: #{e.class.name}\n#{e.message}"
    if Rails.env == 'development'
      $stderr.puts e.backtrace.join("\n")
    end
  end

end
