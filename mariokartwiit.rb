#!/usr/bin/env ruby
## MarioKarTwiit
## Finds Mario Kart Wii codes through your friends' timelines on Twitter.
## Use it with your twitter username like so:
##     ruby mariokartwiit.rb username
#
# Needs the json gem:
#     sudo gem install json
#
# TODO:
#  - Go further back than 20 statuses per friend
#  - Deal with people with more than 100 friends
#  - Turn it into a webapp
#
# By Sunny Ripert - http://sunfox.org
# Under the WTFPL - http://sam.zoy.org/wtfpl/
# Learn more about the Twitter API over here: http://twitter.com/help/api

require 'open-uri'
require 'rubygems'
require 'json'

MARIO_KART_CODE_RE = /(\d{4}-\d{4}-\d{4})/

# For each Wii Mario Kart codefound, yields a user hash containing his name,
# his screen name, the mario kart code and the full status hash that matched.
# Returns an array of it all, too.
#
#   mariokartwiits_for("sunfox")
#   # => [{"screen_name" => "adylk", "name" => "Audrey", "code" => "9837-...
#         ..., "status" => {"text" => "My Mario Kart Wii Code is ..., ...}]
def mariokartwiits_for(username)
  friends = []
  friends = JSON.parse(open("http://twitter.com/statuses/friends/#{username}.json?lite=true").read)
  friends.each do |friend|
    statuses = JSON.parse(open("http://twitter.com/statuses/user_timeline/#{friend["screen_name"]}.json").read)
    statuses.each do |status|
      if status['text'] =~ MARIO_KART_CODE_RE
        friend["code"] = $1
        friend["status"] = status
        friends << friend
        yield friend if block_given?
        break
      end
    end
  end
  friends
end

# Usage is made of oranges and lemonade and lines starting with "##"
def usage
  open(__FILE__).read.grep(/^## ?/).join.gsub(/^## ?/, '')
end

if __FILE__ == $0
  abort usage if ARGV.size < 1
  mariokartwiits_for(ARGV.first) do |friend|
    puts "#{friend["name"]}: #{friend["code"]}"
  end
end
