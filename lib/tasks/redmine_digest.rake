namespace :redmine_digest do

  desc 'Create digest_rule for all users'
  task create_digest: [:environment] do
    puts "#{Time.now} Create digest for all users"
    count=0
    #send_digests DigestRule.active.daily
    User.find_each() do |user|
      #puts user.inspect
      puts "rule #{count}"
      t = user.digest_rules.create(
          name:             'test',
          notify:           DigestRule::DIGEST_ONLY,
          recurrent:        DigestRule::MONTHLY,
          project_selector: DigestRule::ALL,
          event_ids: %w(issue_created project_changed subject_changed assignee_changed status_changed percent_changed version_changed other_attr_changed attachment_added description_changed comment_added),
          # event_ids: DigestEvent::TYPES
      )

      # t = DigestRule.new
      # t.user = user
      # t.name = "default_digest_1"
      # t.active =true
      # t.recurrent = DigestRule::DAILY
      # t.project_selector = DigestRule::MEMBER
      # t.event_ids = DigestEvent::TYPES
      # t.notify = DigestRule::DIGEST_ONLY
      # t.template = DigestRule::TEMPLATE_SHORT
      # t.save!
       puts t.inspect
      count=count+1
    end
    puts "Created #{count} digest rules"
  end

  desc 'Send daily digests by all active rules'
  task send_daily: [:environment] do
    puts "#{Time.now} Send daily digests."
    send_digests DigestRule.active.daily
  end

  desc 'Send weekly digests by all active rules'
  task send_weekly: [:environment] do
    puts "#{Time.now} Send weekly digests."
    send_digests DigestRule.active.weekly
  end

  desc 'Send monthly digests by all active rules'
  task send_monthly: [:environment] do
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
