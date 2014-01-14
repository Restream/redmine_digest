# Redmine Digest plugin

[![Build Status](https://travis-ci.org/Undev/redmine_digest.png)](https://travis-ci.org/Undev/redmine_digest)
[![Code Climate](https://codeclimate.com/github/Undev/redmine_digest.png)](https://codeclimate.com/github/Undev/redmine_digest)

Send daily/weekly/monthly digest

## Description

With this plugin redmine users can create some digest rules and receive digests every day/week/month.

## Installation

This plugin requires other plugin - https://github.com/Undev/redmine__select2
Before installing this plugin install the redmine__select2 plugin

1. Copy plugin directory into REDMINE_ROOT/plugins.
If you are downloading the plugin directly from GitHub,
you can do so by changing into your REDMINE_ROOT directory and issuing a command like

        git clone https://github.com/Undev/redmine_digest.git plugins/redmine_digest

2. Run the following command to run migrations (make a db backup before).

        bundle exec rake redmine:plugins:migrate RAILS_ENV=production

3. You now need to restart Redmine so that it shows the newly installed plugin in the list of installed plugins ("Administration -> Plugins").
4. Configure crontab to send digests. Here is example that send daily digests every day at 01:00, weekly digest every monday at 02:00 and monthly digest every 1 day of the month at 03:00

        0 1 * * * rvm use ruby-1.9.3 && cd /var/www/redmine && RAILS_ENV=production bundle exec rake redmine_digest:send_daily
        0 2 * * 1 rvm use ruby-1.9.3 && cd /var/www/redmine && RAILS_ENV=production bundle exec rake redmine_digest:send_weekly
        0 3 1 * * rvm use ruby-1.9.3 && cd /var/www/redmine && RAILS_ENV=production bundle exec rake redmine_digest:send_monthly

## Digest rules

You can create any number of digest rules.

![Digest rules](https://raw.github.com/Undev/redmine_digest/master/screenshot/digest_rules.png "Digest rules")

Go to the my account page and create a rule by clicking "New digest rule" button.

Short template:

![Digest rule form](https://raw.github.com/Undev/redmine_digest/master/screenshot/digest_rule_form.png "Digest rule form")

Detail template:

![Digest (short template)](https://raw.github.com/Undev/redmine_digest/master/screenshot/short.png "Digest (short template)")

![Digest (detail template)](https://raw.github.com/Undev/redmine_digest/master/screenshot/detail.png "Digest (detail template)")

## License

Copyright (C) 2013 Undev.ru

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
