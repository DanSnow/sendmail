#!/usr/bin/env ruby
# encoding: UTF-8

require 'mail'
require 'ruby-progressbar'

require_relative 'config'
require_relative 'logger'
require_relative 'exception'
require_relative 'mail_address'
require_relative 'mail_content'

class Sendmail
  include Logger
  include Handler::Retry

  def initialize(addr_limit = nil)
    load_config

    logger.debug(@options)

    load_mail(addr_limit)
    setup
  end

  def run
    progressbar = ProgressBar.create total: total_mail, format: '|%B|%c/%C %E'

    @mail_address.each do |address|
      begin
        with_retry do
          sendmail(address)
        end
      rescue RuntimeError => e
        logger.error e
        @mail_address.add_fail address
      end
      progressbar.increment
    end

    progressbar.finish
    report
  end

  def report
    unless mail_address.fails.empty?
      logger.warn "Can't send to #{mail_address.fails.join("\n")}"
    end

    mail_address.fails
  end

  private

  def sendmail(address)
    mail = Mail.new do
      to address
      from @sender
      reply_to @sender
      subject mail_content.title
    end

    @mail_content.attach_image(mail)

    mail.html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body mail_content.to_s
    end

    mail.deliver
  end

  def load_config
    @options = {
      address: Config.smtp_host,
      port: Config.smtp_port,
      domain: Config.smtp_domain,
      enable_starttls_auto: true
    }
    @options.merge!(
      user_name: Config.smtp_username,
      password: Config.smtp_password,
      authentication: Config.smtp_auth
    ) if Config.smtp_auth != 'none'

    @sender = Config.sender
  end

  def load_mail(addr_limit)
    @mail_content = MailContent.new(Config.email_content)
    @mail_address = MailAddress.new(Config.email_list, addr_limit)

    @total_mail = mail_address.size
  end

  def setup
    Mail.defaults do
      delivery_method :smtp, @options
    end
  end
end

