#!/usr/bin/env ruby
# encoding: UTF-8

require 'bundler/setup'
require 'mail'
require 'logging'
require 'ruby-progressbar'

require_relative 'config'
require_relative 'logger'
require_relative 'mail_address'
require_relative 'mail_content'

logger = Logging.logger[APP_LOGGER]
mail_content = MailContent.new(Config.email_content)
mail_address = MailAddress.new(Config.email_list)

def with_retry
  retry_time = 0

  begin
    yield
  rescue StandardError => e
    logger.error "Exception: #{e.class}"
    logger.error e.to_s
    logger.error e.backtrace.join("\n")
    retry_time += 1
    if retry_time < 3
      logger.info 'Retry'
      retry
    end
  end

  if retry_time == 3 # When too many error, give more sleep
    sleep 5
    fail %q(Too many retry)
  end
end

options = {
  address: Config.smtp_host,
  port: Config.smtp_port,
  domain: Config.smtp_domain,
  enable_starttls_auto: true
}

if Config.smtp_auth != 'none'
  options.merge!(user_name: Config.smtp_username,
                password: Config.smtp_password,
                authentication: Config.smtp_auth
               )
end

logger.debug "Options: #{options}"

Mail.defaults do
  delivery_method :smtp, options
end

total_mail = mail_address.size
progressbar = ProgressBar.create total: total_mail, format: '|%B|%c/%C %E'

mail_address.each do |address|
  begin
    with_retry do
      mail = Mail.new do
        to address
        from Config.sender
        reply_to Config.sender
        subject mail_content.title
      end

      mail_content.attach_image(mail)

      mail.html_part = Mail::Part.new do
        content_type 'text/html; charset=UTF-8'
        body mail_content.to_s
      end

      mail.deliver
    end
  rescue RuntimeError => e
    logger.error e
    mail_address.add_fail address
  end
  progressbar.increment
end

progressbar.finish

unless mail_address.fails.empty?
  logger.warn "Can't send to #{mail_address.fails.join("\n")}"
end
