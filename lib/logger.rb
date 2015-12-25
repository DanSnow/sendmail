#!/usr/bin/env ruby
# encoding: UTF-8

require 'logging'

require_relative 'config'

APP_LOGGER = 'sendmail'

logger = Logging.logger[APP_LOGGER]
logger.level = Config.log.to_sym

logger.add_appenders Logging.appenders.stdout, Logging.appenders.file('mail.log')

logger.info 'Start logger'

module Log
  def logger
    @logger ||= Logging.logger[APP_LOGGER]
  end
end
