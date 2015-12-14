#!/usr/bin/env ruby
# encoding: UTF-8

require 'figaro'

Figaro.application = Figaro::Application.new(path: 'application.yml')
Figaro.load
Figaro.require_keys(
  'smtp_host',
  'smtp_port',
  'smtp_domain',
  'smtp_username',
  'smtp_password',
  'smtp_auth'
)

Config = Figaro.env
