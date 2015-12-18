#!/usr/bin/env ruby
# encoding: UTF-8

require 'forwardable'

class MailAddress
  extend Forwardable

  attr_reader :address, :filename, :fails

  def initialize(filename)
    @filename = filename
    @fails = []
    File.open(filename, 'r') do |f|
      @address = f.readlines.map(&:chomp)
    end
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
