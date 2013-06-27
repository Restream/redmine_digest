class DigestMailer < ActionMailer::Base

  helper :application
  helper :digest_rules

  include Redmine::I18n

  layout 'digest'

  # Overview
  # Changed issues
  #   New Status (group issues by status)
  #     Issue (Issues sorted by last change time)
  #       #000 subject -> (% done, assignee, comments)
  #
  def digest_email(digest)

    redmine_headers 'Digest-Name' => digest.name,
                    'Digest-Recurrent' => digest.recurrent,
                    'Digest-Projects' => digest.project_selector,
                    'Digest-From' => digest.time_from,
                    'Digest-To' => digest.time_to

    set_language_if_valid digest.user.language

    @digest = digest

    mail :to => digest.user.mail,
         :subject => l(:text_digest_subject,
                       :recurrent => l(digest.recurrent, :scope => 'recurrent_types'),
                       :name => digest.name)
  end

  def initialize(*args)
    @initial_language = current_language
    set_language_if_valid Setting.default_language
    super
  end

  # Sends emails synchronously in the given block
  def self.with_synched_deliveries(&block)
    saved_method = ActionMailer::Base.delivery_method
    if m = saved_method.to_s.match(%r{^async_(.+)$})
      synched_method = m[1]
      ActionMailer::Base.delivery_method = synched_method.to_sym
      ActionMailer::Base.send "#{synched_method}_settings=", ActionMailer::Base.send("async_#{synched_method}_settings")
    end
    yield
  ensure
    ActionMailer::Base.delivery_method = saved_method
  end

  def mail(headers={})
    headers.merge! 'X-Mailer' => 'Redmine',
                   'X-Redmine-Host' => Setting.host_name,
                   'X-Redmine-Site' => Setting.app_title,
                   'X-Auto-Response-Suppress' => 'OOF',
                   'Auto-Submitted' => 'auto-generated',
                   'From' => Setting.mail_from,
                   'List-Id' => "<#{Setting.mail_from.to_s.gsub('@', '.')}>"

    super headers

    set_language_if_valid @initial_language
  end

  private

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v.to_s }
  end

end
