#!/usr/bin/env ruby
# encoding: UTF-8

require 'forwardable'

class MailAddress
  extend Forwardable

  attr_reader :address, :filename, :fails, :limit

  def initialize(filename, limit = nil)
    @filename = filename
    @fails = []
    @limit = limit
    File.open(filename, 'r') do |f|
      @address = f.readlines.map(&:chomp)
    end

    @address.take limit if limit
  end

  def each
    num = 0
    @address.each do |addr|
      num = (num + 1) % 10
      sleep 3 if num.zero?
      yield addr
    end
  end

  def add_fail(addr)
    @fails << addr
  end

  def_delegators :@address, :size
end
