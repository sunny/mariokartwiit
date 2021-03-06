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

class MarioKarTwiit
  MARIO_KART_CODE_RE = /(\d{4}-\d{4}-\d{4})/


  # Returns an array of twitter friends who have a Wii Mario Kart. The user hash
  # contains the code, a name, a screen_name and the full status hash that matched.
  #
  #   mariokartwiits_for("sunfox")
  #   # => [{"screen_name" => "adylk", "name" => "Audrey", "code" => "9837-...
  #         ..., "status" => {"text" => "My Mario Kart Wii Code is ..., ...}]
  def self.friends_with_codes_for(username)
    friends_with_codes = []
    followers_for(username).each do |friend|
      friend["statuses"].each do |status|
        if status['text'] =~ MARIO_KART_CODE_RE
          friend["code"] = $1
          friend["status"] = status
          friends_with_codes << friend
          break
        end
      end
    end
    friends_with_codes
  end

  # Returns an array of user hashes with all their latest statuses
  def self.followers_for(username)
    friends = JSON.parse(open("http://twitter.com/statuses/friends/#{username}.json?lite=true").read)
    threads = []
    statuses = []
    friends.each do |friend|
      threads << Thread.new(friend) do |user|
        friend["statuses"] = JSON.parse(open("http://twitter.com/statuses/user_timeline/#{user["screen_name"]}.json").read)
      end
    end
    threads.each { |thread| thread.join }
    friends
  end
end

# Usage is made of oranges and lemonade and lines starting with "##"
def usage
  open(__FILE__).read.grep(/^## ?/).join.gsub(/^## ?/, '')
end

if __FILE__ == $0
  abort usage if ARGV.size < 1
  MarioKarTwiit.friends_with_codes_for(ARGV.first).each do |friend|
    puts "#{friend["name"]}: #{friend["code"]}"
  end
end
