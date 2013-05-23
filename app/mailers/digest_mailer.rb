class DigestMailer < ActionMailer::Base

  helper :digest_mailer

  include Redmine::I18n

  layout 'digest'

  class << self

    def default_url_options
      { :host => Setting.host_name, :protocol => Setting.protocol }
    end

  end

  # Overview
  # Changed issues
  #   New Status (group issues by status)
  #     Issue (Issues sorted by last change time)
  #       #000 subject -> (% done, assignee, comments)
  #
  def digest_email(digest)

    redmine_headers 'digest-name' => digest.name,
                    'digest-recurrent' => digest.recurrent,
                    'digest-projects' => digest.project_selector,
                    'digest-from' => digest.date_from,
                    'digest-to' => digest.date_to

    set_language_if_valid digest.user.language

    @digest = digest

    mail :to => digest.user.mail,
         :subject => l(:text_digest_subject,
                       :recurrent => digest.recurrent,
                       :name => digest.name)
  end

  def initialize(*args)
    @initial_language = current_language
    set_language_if_valid Setting.default_language
    super
  end

  private

  # Appends a Redmine header field (name is prepended with 'X-Redmine-')
  def redmine_headers(h)
    h.each { |k,v| headers["X-Redmine-#{k}"] = v.to_s }
  end

end
