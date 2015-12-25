#!/usr/bin/env ruby
# encoding: UTF-8

require_relative 'logger'

module Handler
  module Retry
    include ::Log

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
  end
end
