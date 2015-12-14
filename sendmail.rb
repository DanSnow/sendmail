#!/usr/bin/env ruby
# encoding: UTF-8

require 'bundler/setup'
require 'mail'

require_relative 'config'
require_relative 'mail_content'

mail_content = MailContent.new('content.html')

def mail_list(filename)
  num = 0
  File.read(filename).each_line do |address|
    num = (num + 1) % 10
    if num.zero?
      puts 'sleep'
      sleep 3
    end
    yield address
  end
end

options = {
  address: Config.smtp_host,
  port: Config.smtp_port,
  domain: Config.smtp_domain,
  enable_starttls_auto: true
}

if Config.smtp_auth != 'none'
  options.merge(user_name: Config.smtp_username,
                password: Config.smtp_password,
                authentication: Config.smtp_auth
               )
end

Mail.defaults do
  delivery_method :smtp, options
end

mail_list('email') do |address|
  mail = Mail.new do
    to address
    from 'yungru@ccu.edu.tw'
    reply_to 'yungru@ccu.edu.tw'
    subject mail_content.title
  end

  mail_content.attach_image(mail)

  mail.html_part = Mail::Part.new do
    content_type 'text/html; charset=UTF-8'
    body mail_content.to_s
  end

  mail.deliver
end
