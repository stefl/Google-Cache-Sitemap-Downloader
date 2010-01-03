# Google Cache Sitemap Downloader
# Downloads all the links contained in your Google Sitemap XML file from Google Cache
# and saves the raw HTML as a series of files
#
# Author: Stef Lewandowski
# Email: stef@stef.io
# Web: http://stef.io
# Version: 0.1

# Instructions:
#
# Download your Google sitemap as a text file and save it in the same directory as this script
# 
# Then run this script as:
#
# ruby google_cache_sitemap_downloader.rb 'http://mydomain.com' sitemap.xml 'body'

ARGV.each do|a|
  puts "Argument: #{a}"
end

# The URL of your site
BASE_URL = ARGV[0]

# The Google sitemap XML file - should be in the same directory as this script, or the relative path
SITEMAP = ARGV[1]

# An HTML element that should exist on the page to confirm it is correctly imported
# Formatted in a CSS style selector
#
# Eg. If your page contains a DIV with an ID of "main", this value should be '#main'
# If your page contains an H1 tag, you could use 'h1'
# For more complex values, take a look at Nokogiri's CSS style selector: http://nokogiri.org
MATCH_TO_CONFIRM_THE_PAGE_EXISTS = ARGV[2]

# Stop editing here

require "rubygems"
require "crack"
require 'nokogiri'
require 'open-uri'

# You shouldn't need to change these values
ERROR_THRESHOLD = 3 # number of times a google request fails before we exit the script
WAIT_TIME = 2 #number of seconds to wait in-between requests to google 

def filename_from_url (url)
  "results/" + url['loc'].gsub(BASE_URL,'').gsub("/","_-_")
end

puts "Create results directory"
FileUtils.mkdir 'results' rescue puts "Results directory already exists"

sitemap = Crack::XML.parse(File.open(SITEMAP))

error_count = 0
need_to_rerun = false

sitemap["urlset"]["url"].each do |url| #each
  if error_count >= ERROR_THRESHOLD
    puts "TOO MANY ERRORS"
    need_to_rerun = true
    break
  end
  
  # Sleep a short while to stop Google rate limiting us
  sleep WAIT_TIME
  
  puts "Checking #{url['loc']}"
  
  # Get a Nokogiri::HTML:Document for the page we’re interested in...
  unless File.exists?(filename_from_url(url))
    begin
      doc = Nokogiri::HTML(open("http://www.google.com/search?q=cache:#{url['loc']}"))
  
      unless doc.css(MATCH_TO_CONFIRM_THE_PAGE_EXISTS).blank?
        puts "Downloading #{url['loc']} and saving as #{filename_from_url(url)}"
        File.open(filename_from_url(url), 'w') {|f| f.write(doc.to_html) }
      else
        puts "This url doesn't appear to be cached by Google correctly: #{url['loc']}"
      end
    rescue
      puts "There was a problem requesting that page from Google"
      error_count += 1
      need_to_rerun = true
    end
    
  else
    puts "We have already downloaded this page. To re-download delete #{filename_from_url(url)}"
  end
end

if need_to_rerun
  puts "\n\nERROR: Not all pages have been downloaded from Google."
  puts "Google limits the number of pages you can request automatically"
  puts "Please wait a few minutes and try again"
  puts ""
  puts "To check if you can run the script again visit this url in a browser:"
  puts "http://www.google.com/search?q=cache:#{BASE_URL}"
end