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
  include Log
  include Handler::Retry

  def initialize(addr_limit = nil)
    logger.debug 'Initialize sendmail core'
    load_config

    load_mail(addr_limit)
    setup(@options)
    logger.debug 'Initialize success'
  end

  def run
    logger.debug 'Running core'
    progressbar = ProgressBar.create total: @total_mail, format: '|%B|%c/%C %E'

    @mail_address.each do |address|
      begin
        with_retry do
          sendmail(address, @sender, @mail_content)
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
    logger.debug 'Report'
    if @mail_address.fails.empty?
      logger.info 'All success'
    else
      logger.warn "Can't send to #{@mail_address.fails.join("\n")}"
    end

    @mail_address.fails
  end

  private

  def sendmail(address, sender, content)
    logger.debug "Sending email to #{address}"
    mail = Mail.new do
      to address
      from sender
      reply_to sender
      subject content.title
    end

    content.attach_image(mail)

    mail.html_part = Mail::Part.new do
      content_type 'text/html; charset=UTF-8'
      body content.to_s
    end

    mail.deliver
  end

  def load_config
    logger.debug 'Loading config'
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

    logger.debug "Config load #{@options}"
    @sender = Config.sender
    logger.debug "Config sender #{@sender}"
  end

  def load_mail(addr_limit)
    logger.debug 'Loading email list and content'
    @mail_content = MailContent.new(Config.email_content)
    @mail_address = MailAddress.new(Config.email_list, addr_limit)

    @total_mail = @mail_address.size
  end

  def setup(opt)
    logger.debug 'Setup mail'
    Mail.defaults do
      delivery_method :smtp, opt
    end
  end
end

