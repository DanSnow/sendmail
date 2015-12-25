#!/usr/bin/env ruby
# encoding: UTF-8

require 'nokogiri'

class MailContent
  attr_accessor :title

  Image = Struct.new(:path, :element)

  def initialize(source)
    @orig_content = File.read(source)
    @page = Nokogiri.HTML(@orig_content)
    @imgs = {}
    @img_cids = {}
    extract_image
  end

  def title
    @title || extract_title
  end

  def attach_image(mail)
    @imgs.each do |name, data|
      mail.add_file data.path
      cid = mail.attachments[name].cid
      @img_cids[name] = cid
    end

    replace_cid
  end

  def to_s
    @page.to_s
  end

  private

  def replace_cid
    @img_cids.each do |name, cid|
      @imgs[name].element['src'] = "cid:#{cid}"
    end
  end

  def extract_image
    @page.xpath('//img').each do |img|
      path = img['src']
      next if url? path
      next unless file_exist? path
      basename = File.basename(path)
      @imgs[basename] = Image.new(path, img)
    end
  end

  def extract_title
    title = @page.xpath('//head/title').first
    if title.nil?
      STDERR.puts 'Title undefined'
      @title = 'Title'
    else
      @title = title.text
    end
    @title
  end

  def file_exist?(path)
    if File.exist? path
      true
    else
      STDERR.puts "Path: #{path} not exist"
      false
    end
  end

  def url?(path)
    path.start_with?('http://') ||
      path.start_with?('https://') ||
      path.start_with?('data:')
  end
end
