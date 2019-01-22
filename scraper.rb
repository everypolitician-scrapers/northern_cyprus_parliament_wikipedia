#!/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true

require 'pry'
require 'scraped'
require 'scraperwiki'

require 'open-uri/cached'
OpenURI::Cache.cache_path = '.cache'

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
      puts data.reject { |_, v| v.to_s.empty? }.sort_by { |k, _| k }.to_h if ENV['MORPH_DEBUG']
      ScraperWiki.save_sqlite(%i(name party area term), data)
    end
  end
end

ScraperWiki.sqliteexecute('DELETE FROM data') rescue nil
scrape_list('https://en.wikipedia.org/wiki/14th_Parliament_of_Northern_Cyprus')
