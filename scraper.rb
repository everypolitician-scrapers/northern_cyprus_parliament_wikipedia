#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'nokogiri'
require 'pry'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

class String
  def tidy
    gsub(/[[:space:]]+/, ' ').strip
  end
end

def noko_for(url)
  Nokogiri::HTML(open(url).read)
end

def scrape_list(url)
  noko = noko_for(url)
  noko.xpath('//table[.//tr[contains(.,"Member of Parliament")]]').each do |table|
    area = table.xpath('preceding-sibling::h2[1]/span[@class="mw-headline"]').text
    table.xpath('.//tr[td]').each do |tr|
      tds = tr.css('td')
      data = {
        name:     tds[0].text,
        wikiname: tds[0].xpath('.//a[not(@class="new")]/@title').text,
        party:    tds[1].text.tidy,
        area:     area,
        term:     14,
        source:   url,
      }
      ScraperWiki.save_sqlite(%i(name party area term), data)
    end
  end
end

scrape_list('https://en.wikipedia.org/wiki/14th_Parliament_of_Northern_Cyprus')
