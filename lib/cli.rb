#!/usr/bin/env ruby
# encoding: UTF-8

require 'gli'

require_relative 'sendmail'

module CLI
  extend ::GLI::App

  command :run do |cmd|
    cmd.action do |_global_opts, _opts, args|
      sendmail = ::Sendmail.new(args.fetch(0, nil))

      sendmail.run
    end
  end
end
