#!ruby
require 'rubygems'
require 'camping'
require 'mariokartwiit'

Camping.goes :MarioKamping

module MarioKamping::Models
  class User < Base
    validates_uniqueness_of :screen_name
    has_and_belongs_to_many :followers,
      :class_name => "User",
      :join_table => "mariokamping_followers",
      :foreign_key => "followed_id",
      :association_foreign_key => "follower_id"
    
    def User.get(screen_name)
      user = User.find_or_initialize_by_screen_name(screen_name)
      return user unless user.followers.empty?
      
      begin
        MarioKarTwiit.friends_with_codes_for(screen_name).each do |follower|
          user.followers << User.from_hash(follower)
        end
      rescue OpenURI::HTTPError
        return user
      end
      
      user.save
      user
    end
    
    def User.from_hash(hash)
      user = User.find_or_initialize_by_screen_name hash["screen_name"]
      options = {
        :name => hash["name"],
        :status => hash["status"]["text"],
        :status_id => hash["status"]["id"],
        :code => hash["code"],
        :profile_image_url => hash["profile_image_url"]
      }
      user.update_attributes(options) if user.name.nil?
      user
    end
    
  end
  class CreateUsers < V 1.0
    def self.up
      create_table :mariokamping_users do |t|
        t.string :screen_name
        t.string :name
        t.string :profile_image_url
        t.string :code
        t.string :status
        t.integer :status_id
      end
      create_table :mariokamping_followers, :id => false do |t|
        t.integer :followed_id
        t.integer :follower_id
      end
    end
    def self.down
      drop_table :mariokamping_users
      drop_table :mariokamping_followers
    end
  end
end

def MarioKamping.create
  MarioKamping::Models.create_schema
end

module MarioKamping::Controllers
  class Index < R '/'
    def get
      render :index
    end
  end  
  
  class RedirectUser < R '/get'
    def get
      redirect R(Twitter, @input[:user])
    end
  end
  
  def mariokartwiits_for(val)
  end
  
  class Twitter < R '/(\w+)'
    def get(user_name)
      @user = User.get(user_name)
      render :friends
    end
  end
  
  class Stylesheet < R '/style.css'
    def get
      @headers['Content-Type'] = 'text/css'
      "a {
          text-decoration: none;
          color: blue;}
          a:hover {
            text-decoration: underline;}

        body {
          font: 0.75em/1.5 'Lucida Grande', sans-serif;
          color: #333;}

        h2 {}
          h2 input {
            border: 1px dashed #ddd;
            font: inherit;}

        ul {
          width: 700px;
          list-style-type: none;
          padding: 0;}
           ul li {
            border-top: 1px solid #eee;
            clear: left;
            position: relative;
            min-height: 28px;
            padding: 15px 0 15px 60px;}
            ul li a.user {
              padding-right: .5em;}
              ul li a.user img {
                position: absolute;
                top: 5px;
                left: 5px;
                float: left;
                border: 0;}
            ul li strong {
              font-size: 1.2em;}"
    end
  end
  
end

module MarioKamping::Helpers
  def status_text(user)
    status = user.status
    status[user.code] = "<strong>#{user.code}</strong>"
    status.gsub! /([^\w]?)@([a-zA-Z0-9]+)([^\w]?)/,
      '\1<a href="http://twitter.com/\2">@\2</a>\3'
    status
  end
end

module MarioKamping::Views
  def layout
    html do
      head do
        title { 'MarioKarTwiit' }
        link :href => R(Stylesheet), :rel => 'stylesheet', :type => 'text/css'
      end
      body do
        h1 { 'MarioKarTwiit' }
        self << yield
      end
    end
  end
  
  def index
    form :action => 'get' do
      p do
        label(:for => :user) { 'Your twitter username: ' }
        input :name => :user, :id => :user
        input :type => :submit, :value => 'Ok' 
      end
    end
  end
  
  def friends
    form :action => 'get' do
      h2 do
        span { "Codes for " }
        input :name => :user, :value => @user.screen_name
        span { "'s friends..." }
      end
    end
    if @user.followers.empty?
      p { "Sorry, #{@user.screen_name} doesn't seem to be following any twittering mario kart wii players&hellip;" }
    else
      ul.followers do
        @user.followers.each do |user|
          li do
            a.user :href => "http://twitter.com/#{user.screen_name}" do
              img :src => user.profile_image_url, :alt => ""
              strong { user.name }
            end          
            span { status_text(user) }
          end
        end
      end
    end
  end
  
end


