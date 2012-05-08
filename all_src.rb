require 'digest/sha1'

class AccessController < ApplicationController
  def authenticate
    username = params[:username]
    password = params[:password]
    loginfrom = params[:loginfrom]
    
    print "username => " + username
    
    password_hash = Digest::SHA1.hexdigest(password)
    
    print "password_hash => " + password_hash
    
    user = User.find_by_username_and_password_hash(username, password_hash)
    
    if (user.nil?)
      print "user was not found"
    else
      print "user found. verified => [" + user.verified.to_s() + "]"
      
      if (user.image.nil?)
        print "user does not have an avatar "
      else
        print "user has avatar => [" + user.image.filename + "] "
      end
    end
    
    SessionManager.instance.session = Hash.new
    
    if (user.nil? || user.verified == false)
      SessionManager.instance.session[:authenticated] = false
      SessionManager.instance.session[:loginfailed] = true
    else
      SessionManager.instance.session[:authenticated] = true
      SessionManager.instance.session[:user] = user
    end
    
    unless loginfrom.nil?
      print "user came from page => " + loginfrom
      redirect_to loginfrom
    else
      redirect_to '/'
    end
  end
 
  def resetpassword
    print "password request for => " + params[:email]
  end
  
  def logout
    #just destroy the session here ...
    SessionManager.instance.session = nil
    redirect_to '/'
  end
  
  def register
  end
  
  def doregister
    print "doregister "
    @user = User.new
    
    @user.username = params[:username]
    @user.email = params[:email]
    @user.verified = false
    
    verify = SecureRandom.hex(32)
    salt = SecureRandom.hex(16)
    userid = Digest::SHA1.hexdigest((@user.username + salt))
    
    pwd = params[:password]
    pwd_confirm = params[:password_confirmation]
    
    continue = true
    
    if (!pwd.empty? && !pwd_confirm.empty? && (pwd == pwd_confirm))
      print "passwords match " 
      password_hash = Digest::SHA1.hexdigest(pwd)
      @user.password_hash = password_hash
    else
      print "passwords do not match "
      continue = false
    end
      
    @user.verifyguid = verify
    @user.userid = userid
    
    print "created vguid => [" + verify + "] userid => [" + userid + "]"
    
    print "continue => [" + continue.to_s() + "] "
    
    valid = @user.valid?
    
    print "valid => [" + valid.to_s() + "]"
    
    if (!continue)
      @user.errors[:base] << "The passwords entered do not match"
    end
    
    if (continue && valid)
      @user.save
      #user saved successfully, send out the welcome email, prompt user to verify account
      UserMailer.welcome_email(@user, currenthost).deliver
      render 'thankyou'
    else
      #there were errors, probably validation. display the errors on the page
      render 'register'
    end
  end
  
  def verify
    userid = params[:b]
    verifyguid = params[:a]
    
    pending = User.find_by_userid(userid)
    
    if (pending.verified)
      #do nothing, user has been verified already
    else
      pending.verified = true
      
      #DateTime.now gives us in GMT timezone, need to use DateTime.new to add the offset for correct timezone
      x = DateTime.now
      #curr = DateTime.new(x.year, x.month, x.day, x.hour, x.min, x.sec, x.sec_fraction, x.offset)
      #pending.membersince = curr
      pending.membersince = x
      pending.userguid = SecureRandom.hex(32)
      
      pending.save
      
      news = News.new
      news.description = "#{pending.username} just joined the site"
      
      news.link = "/user/viewprofile/#{pending.userguid}"
      news.date = DateTime.now
      
      news.save
    end
    
    redirect_to '/'
  end
end
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  before_filter :init
  
  def init
    @session = SessionManager.instance.session
    @currenthost = "http://" + request.host + ":" + request.port.to_s()
    
    if (requireauth && (@session.nil? || @session[:user].nil?))
      #should maybe redirect to an error page here ?
      redirect_to '/'
    end
  end
  
  def currenthost
    @currenthost
  end
  
  def requireauth
    false
  end
end
class ImageController < ApplicationController
  def get_image
    guid = params[:id]
    a = Image.find_by_imageguid(guid)
    
    if (!a.nil?)
      send_data a.binary_data, :type => a.content_type, :disposition => 'inline'
    else
      send_data nil
    end
  end
  
  def get_avatar
    logger.debug("get_avatar")
    
    user = params[:id]
    u = User.find_by_userguid(user)
    
    if (!u.nil?)
      if (!u.image.nil?)
        logger.debug("image not null, returning avatar")
        send_data u.image.binary_data, :type => u.image.content_type, :disposition => 'inline'
      else
        logger.debug("no avatar, returning nil")
        send_data nil
      end
    else
      logger.debug("no user found")
      send_data nil
    end
  end
end
class IotmController < ApplicationController
  def list
    @nominations = Nomination.find_all_by_month(DateTime.now.month)
  end
  
  def vote
    itemguid = params[:itemguid]
    logger.debug("vote for => [#{itemguid}]")
  end

  def previous
    months = Nomination.select(:month).uniq
    @winners = Array.new
    i = 0
    
    months.each do |month|
      if (month.month == DateTime.now.month)
        logger.debug("current month, not processing")
        next
      end
      
      logger.debug("processing nominations for month => [#{month.month}]")
      nominations = Nomination.find_all_by_month(month.month)
      current = nominations.first
      
      nominations.each do |n|
        if (!n.votes.empty? && !current.votes.empty? && n.votes.count > current.votes.count)
          current = n
        end
      end
      
      if (!current.nil? && !current.votes.empty?)
        logger.debug("adding to list of winners => [#{current.item.description}], with #{current.votes.count} votes")
        @winners[i] = current
        i += 1
      end
    end
  end
  
  def requireauth
    true
  end
endclass ItemController < ApplicationController
  def new
    @categories = Category.all
  end
  
  def manage
    @items = SessionManager.instance.session[:user].items.reload
  end
  
  def save(params)
    print "adding item to database "
      guid = params[:itemref]
     
      @item = Item.find_by_itemguid(guid)
      @item.itemsaved = true;
      @item.description = params[:description]
      @item.category_id = params[:category]
      
      if (!params[:visible].nil? && params[:visible] == "on")
        @item.visible = true
        
        news = News.new
        news.description = "#{SessionManager.instance.session[:user].username} added a new item - #{@item.description}"
        news.link = "/items/details/#{guid}"
        news.date = DateTime.now
        
        news.save
      else
        @item.visible = false
      end
      
      @item.user_id = SessionManager.instance.session[:user].id
      
      @item.save
      
      redirect_to '/user/inventory/manage'
  end
  
  def newimg(params)
    guid = params[:itemref]
      print "saving image to item [" + guid + "]"
      @item = Item.find_by_itemguid(guid)
      
      input = params[:image]
      
      filename = input.original_filename
      content_type = input.content_type.chomp
      binary_data = input.read
      imageguid = SecureRandom.hex(32)
      
      @item.images.create(:filename => filename, :content_type => content_type, :binary_data => binary_data, :imageguid => imageguid)  
      
      @item.save      
          
      @categories = Category.all
      render 'new'
  end
  
  def imagesforitem
    itemguid = params[:id]
    item = Item.find_by_itemguid(itemguid)
    
    coll = Array.new
    i = 0
    
    item.images.each do |img|
      coll[i] = img.imageguid
      i += 1
    end
    
    render :json => coll
  end
  
  def create
    item = Item.new
    
    item.itemsaved = true;
    item.description = params[:description]
    item.category_id = params[:category]
    item.itemguid = SecureRandom.hex(32)
    
    #need to call save here in order to create image children
    item.save
    
    params.each do |p|
      name = p[0].to_s()
      value = p[1]
      
      #loop through all images submitted, add to the item
      if (name.starts_with?("image_"))
        filename = value.original_filename
        logger.debug("adding image => [#{filename}]")
        content_type = value.content_type.chomp
        binary_data = value.read
        imageguid = SecureRandom.hex(32)
        
        item.images.create(:filename => filename, :content_type => content_type, :binary_data => binary_data, :imageguid => imageguid)  
      end
    end
    
    if (!params[:visible].nil? && params[:visible] == "on")
      item.visible = true
      
      news = News.new
      news.description = "#{SessionManager.instance.session[:user].username} added a new item - #{item.description}"
      news.link = "/items/details/#{item.itemguid}"
      news.date = DateTime.now
      
      news.save
    else
      item.visible = false
    end
    
    item.user_id = SessionManager.instance.session[:user].id
    
    item.save
  
    redirect_to '/user/inventory/manage'
  end
  
  def edit
    if (params[:submit] == "Delete Selected")
      delete(params)
    elsif (params[:submit] == "Add Item")
      redirect_to '/user/inventory/new'
    end
  end
  
  def edititem
    @item = Item.find_by_itemguid(params[:id])
    @categories = Category.all
    render 'new'
  end
  
  def delete(params)
    params.each do |p|
      name = p[0].to_s()
      value = p[1].to_s()
      
      if (name.starts_with?("item_"))
        logger.debug("selected => [" + name + "]")
        rem = name.length - 5
        logger.debug("remainder length is " + rem.to_s())
        itemguid = name[5, rem]
        logger.debug("itemguid => [" + itemguid + "]")
        item = Item.find_by_itemguid(itemguid)
        
        if (item.nil?)
          print "could not find item "
        else
          print "item found. id => [" + item.id.to_s() + "]"
          Item.delete(item.id)
        end
      end
    end
    
    redirect_to '/user/inventory/manage'
  end
  
  def browse
    #filter 
    cat = params[:category]
    search = params[:filter_string]
    
    if (!search.nil? && !search.empty?)   
      logger.debug("search supplied => [#{search}]")
         
      if (!cat.nil? && cat != "-1")
        logger.debug("category supplied => [#{cat}]")
        @items = Item.allsaved.where("description like ?", "%#{search}%").find_all_by_category_id(cat)
      else
        logger.debug("no category supplied");
        @items = Item.allsaved.where("description like ?", "%#{search}%")
      end
    elsif (!cat.nil? && cat != "-1")
      @items = Item.allsaved.find_all_by_category_id(cat)      
    else
      @items = Item.allsaved
    end  
    
    @categories = Category.all
  end 
  
  def details
    itemguid = params[:id]
    @item = Item.allsaved.find_by_itemguid(itemguid)
  end
  
  def rate
    itemguid = params[:itemguid]
    rating = params[:rating]
    
    userid = SessionManager.instance.session[:user].id
    
    @item = Item.allsaved.find_by_itemguid(itemguid)
    @item.ratings.create(:value => rating, :createdby => :userid, :ratingdate => DateTime.now)
    @item.save
    
    render 'details'
  end
  
  def nominate
    itemguid = params[:itemguid]
    @item = Item.find_by_itemguid(itemguid)
    
    #first check if this item has been nominated in this month before
    @nomination = Nomination.find_by_item_id_and_month(@item.id, DateTime.now.month)
    
    if (!@nomination.nil?)
      @nomination.errors[:base] << "This item has already been nominated in the current month"
    else
      @nomination = Nomination.new
      @nomination.finished = false
      @nomination.month = DateTime.now.month
    
      @nomination.save
    
      @nomination.user = SessionManager.instance.session[:user]
      @nomination.item = @item
    
      @nomination.save
    end
    
    render 'details'
  end
  
  def requireauth
    true
  end
end
class UserController < ApplicationController
  def profile
    @user = SessionManager.instance.session[:user]
  end
  
  def saveprofile
    print "saveprofile "
    avatar = params[:avatar]
    img = UploadProcessor.new.save_image(avatar)
    @user = SessionManager.instance.session[:user]    
    @user.image = img
    @user.save
    SessionManager.instance.session[:user] = @user   
    redirect_to '/user/profile/manage'
  end
  
  def editprofile
    @user = SessionManager.instance.session[:user]
  end
  
  def userlist
    @users = User.activeusers
  end
  
  def viewprofile
    @user = User.find_by_userguid(params[:id])
  end
  
  def requireauth
    true
  end
end
class WelcomeController < ApplicationController
  def index
    @user = User.new
    @news = News.all
  end
  
  def index2
    render :layout => false
  end
end
module AccessHelper
end
module ApplicationHelper
end
module ImageHelper
end
module ImagecontrollerHelper
end
module IotmHelper
end
module ItemHelper
end
module UserHelper
end
module WelcomeHelper
end
require 'digest/sha1'

class UserMailer < ActionMailer::Base
  default :from => "ryno.genius@gmail.com"
  
  def welcome_email(user, host)
    #sends the validation email when a user signs up
    @user = user
    print "verify => " + user.verifyguid
    @confirm_url = host + "/access/verify?a=" + user.verifyguid + "&b=" + user.userid
    print "verify url => [" + @confirm_url + "]"
    mail(:to => user.email, :subject => "Please verify your email address")
  end
  
  def forgot_password_email(email) 
    
  end
end
class Avatar < Uploads
endclass Category < ActiveRecord::Base
  has_many    :items
end
class Image < ActiveRecord::Base
  belongs_to :imageable, :polymorphic => true
end
class Item < ActiveRecord::Base
  has_many :images, :as => :imageable
  has_many :ratings, :as => :rateable
  
  scope :allsaved, where(:itemsaved => true)
end
class News < ActiveRecord::Base
end
class Nomination < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :item
  has_many    :votes
end
class Rating < ActiveRecord::Base
  belongs_to      :rateable, :polymorphic => true
end
class SessionManager
  include Singleton
  
  def initialize
    @authenticated = false
  end
  
  def authenticated
    @authenticated
  end
  
  def authenticated=(authenticated)
    @authenticated=authenticated
  end
  
  def session
    @session
  end
  
  def session=(session)
    @session=session
  end
endclass UploadProcessor  
  def save_image(input)
    @i = Image.new
    @i.filename = input.original_filename
    @i.content_type = input.content_type.chomp
    @i.binary_data = input.read
    @i.imageguid = SecureRandom.hex(32)
    @i.save
    @i
  end
endclass Uploads < ActiveRecord::Base
end
class User < ActiveRecord::Base
  validates :username, :uniqueness => { :is => true, :message => "has already been taken. Please choose another username" }
  validates :email, :uniqueness => { :is => true, :message => "has already been used for registration" }, :format => { :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i, :message => "is not a valid email address" }
  validates :username, :email, :presence => { :is => true, :message => "needs to be supplied" }
  #validates :password_hash, :presence => {:is => true, :message => ""}
  
  has_one :image, :as => :imageable
  has_many :items
  has_many :ratings, :as => :rateable
  
  scope :activeusers, where(:verified => true) 
end
class Vote < ActiveRecord::Base
    belongs_to    :user
end
require File.expand_path('../boot', __FILE__)

require 'rails/all'

if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require(*Rails.groups(:assets => %w(development test)))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

module Theswopspace
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    # config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Enable the asset pipeline
    config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    config.assets.version = '1.0'
  end
end
require 'rubygems'

# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' if File.exists?(ENV['BUNDLE_GEMFILE'])
# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Theswopspace::Application.initialize!
Theswopspace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Log error messages when you accidentally call methods on nil.
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Only use best-standards-support built into browsers
  config.action_dispatch.best_standards_support = :builtin

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  config.active_record.auto_explain_threshold_in_seconds = 0.5

  # Do not compress assets
  config.assets.compress = false

  # Expands the lines which load the assets
  config.assets.debug = true
  
  
  #mailer smtp settings
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    :address              => "email-smtp.us-east-1.amazonaws.com",
    :port                 => 587,
    :user_name             => "AKIAIW5W2HYMCQZD7WGQ",
    :password             => "Allj0V0962Zybsmc6JYPhSoUormSr4dgkCnA2N4HJ94k",
    :authentication       => 'plain',
    :enable_starttls_auto => true
  }
end
Theswopspace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # Code is not reloaded between requests
  config.cache_classes = true

  # Full error reports are disabled and caching is turned on
  config.consider_all_requests_local       = false
  config.action_controller.perform_caching = true

  # Disable Rails's static asset server (Apache or nginx will already do this)
  config.serve_static_assets = false

  # Compress JavaScripts and CSS
  config.assets.compress = true

  # Don't fallback to assets pipeline if a precompiled asset is missed
  config.assets.compile = false

  # Generate digests for assets URLs
  config.assets.digest = true

  # Defaults to Rails.root.join("public/assets")
  # config.assets.manifest = YOUR_PATH

  # Specifies the header that your server uses for sending files
  # config.action_dispatch.x_sendfile_header = "X-Sendfile" # for apache
  # config.action_dispatch.x_sendfile_header = 'X-Accel-Redirect' # for nginx

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  # config.force_ssl = true

  # See everything in the log (default is :info)
  # config.log_level = :debug

  # Prepend all log lines with the following tags
  # config.log_tags = [ :subdomain, :uuid ]

  # Use a different logger for distributed setups
  # config.logger = ActiveSupport::TaggedLogging.new(SyslogLogger.new)

  # Use a different cache store in production
  # config.cache_store = :mem_cache_store

  # Enable serving of images, stylesheets, and JavaScripts from an asset server
  # config.action_controller.asset_host = "http://assets.example.com"

  # Precompile additional assets (application.js, application.css, and all non-JS/CSS are already added)
  # config.assets.precompile += %w( search.js )

  # Disable delivery errors, bad email addresses will be ignored
  # config.action_mailer.raise_delivery_errors = false

  # Enable threaded mode
  # config.threadsafe!

  # Enable locale fallbacks for I18n (makes lookups for any locale fall back to
  # the I18n.default_locale when a translation can not be found)
  config.i18n.fallbacks = true

  # Send deprecation notices to registered listeners
  config.active_support.deprecation = :notify

  # Log the query plan for queries taking more than this (works
  # with SQLite, MySQL, and PostgreSQL)
  # config.active_record.auto_explain_threshold_in_seconds = 0.5
end
Theswopspace::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # The test environment is used exclusively to run your application's
  # test suite. You never need to work with it otherwise. Remember that
  # your test database is "scratch space" for the test suite and is wiped
  # and recreated between test runs. Don't rely on the data there!
  config.cache_classes = true

  # Configure static asset server for tests with Cache-Control for performance
  config.serve_static_assets = true
  config.static_cache_control = "public, max-age=3600"

  # Log error messages when you accidentally call methods on nil
  config.whiny_nils = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Raise exceptions instead of rendering exception templates
  config.action_dispatch.show_exceptions = false

  # Disable request forgery protection in test environment
  config.action_controller.allow_forgery_protection    = false

  # Tell Action Mailer not to deliver emails to the real world.
  # The :test delivery method accumulates sent emails in the
  # ActionMailer::Base.deliveries array.
  config.action_mailer.delivery_method = :test

  # Raise exception on mass assignment protection for Active Record models
  config.active_record.mass_assignment_sanitizer = :strict

  # Print deprecation notices to the stderr
  config.active_support.deprecation = :stderr
end
# Be sure to restart your server when you modify this file.

# You can add backtrace silencers for libraries that you're using but don't wish to see in your backtraces.
# Rails.backtrace_cleaner.add_silencer { |line| line =~ /my_noisy_library/ }

# You can also remove all the silencers if you're trying to debug a problem that might stem from framework code.
# Rails.backtrace_cleaner.remove_silencers!
# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format
# (all these examples are active by default):
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end
#
# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections do |inflect|
#   inflect.acronym 'RESTful'
# end
# Be sure to restart your server when you modify this file.

# Add new mime types for use in respond_to blocks:
# Mime::Type.register "text/richtext", :rtf
# Mime::Type.register_alias "text/html", :iphone
# Be sure to restart your server when you modify this file.

# Your secret key for verifying the integrity of signed cookies.
# If you change this key, all old signed cookies will become invalid!
# Make sure the secret is at least 30 characters and all random,
# no regular words or you'll be exposed to dictionary attacks.
Theswopspace::Application.config.secret_token = '0db0a5873ebef3aa276fada99f2a12a68b53023629a27b335707b7108b2231efe972f2cc20ee4e98b7d099f6198520aac01cc4ed76e4452ac7eec2c07c2b6d0e'
# Be sure to restart your server when you modify this file.

Theswopspace::Application.config.session_store :cookie_store, :key => '_theswopspace_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rails generate session_migration")
# Theswopspace::Application.config.session_store :active_record_store
# Be sure to restart your server when you modify this file.
#
# This file contains settings for ActionController::ParamsWrapper which
# is enabled by default.

# Enable parameter wrapping for JSON. You can disable this by setting :format to an empty array.
ActiveSupport.on_load(:action_controller) do
  wrap_parameters :format => [:json]
end

# Disable root element in JSON by default.
ActiveSupport.on_load(:active_record) do
  self.include_root_in_json = false
end
Theswopspace::Application.routes.draw do
  get "iotm/list"

  get "iotm/previous"

  get "welcome/index"

  # The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action
  
  #access mappings
  match 'access/authenticate' => 'access#authenticate', :via => :post
  match 'access/logout' => 'access#logout'
  match 'access/forgot' => 'access#forgot'
  match 'access/resetpassword' => 'access#resetpassword', :via => :post
  match 'access/register' => 'access#register'
  match 'access/doregister' => 'access#doregister'
  match 'access/verify' => 'access#verify', :via => :get
  
  #user profile mappings
  match 'user/profile' => 'user#profile', :via => :get
  match 'user/saveprofile' => 'user#saveprofile', :via => :post
  match 'user/profile/manage' => 'user#editprofile', :via => :get
  match 'user/viewprofile/:id' => 'user#viewprofile', :via => :get
  match 'users/list' => 'user#userlist', :via => :get
  
  #image controller mappings
  match 'image/avatar/:id' => 'image#get_avatar', :via => :get
  match 'image/get/:id' => "image#get_image", :via => :get
  
  #item mappings
  match 'user/inventory/manage' => 'item#manage', :via => :get
  match 'user/inventory/new' => 'item#new'
  match 'item/create' => 'item#create', :via => :post
  match 'item/edit/:id' => 'item#edititem', :via => :get
  match 'item/edit' => 'item#edit', :via => :post
  match 'items/browse' => 'item#browse'
  match 'items/details/:id' => 'item#details'
  match 'items/rate' => 'item#rate', :via => :post
  match 'items/images/:id' => 'item#imagesforitem', :via => :get
  match 'items/nominate' => 'item#nominate', :via => :post
  
  #item of the month mappings
  match 'iotm/list' => 'iotm#list', :via => :get
  match 'iotm/vote' => 'iotm#vote', :via => :post

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'
  root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
class CreateUsers < ActiveRecord::Migration
  def up
    create_table :users do |t|
      t.string            :username
      t.string            :password_hash
      t.string            :userid
      t.boolean           :verified
      t.string            :verifyguid
      t.datetime          :membersince
      t.string            :email
    end
  end
end
class CreateImages < ActiveRecord::Migration
  def up
    create_table :images do |t|
      t.string        :filename
      t.string        :content_type
      t.binary        :binary_data
      t.references    :imageable, :polymorphic => true
    end
  end
end
class AddUserGuid < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.string        :userguid
    end
  end

  def down
  end
end
class AddImageGuid < ActiveRecord::Migration
  def up
    change_table :images do |t|
      t.string        :imageguid
    end
  end

  def down
  end
end
class CreateCategories < ActiveRecord::Migration
  def change
    create_table :categories do |t|
      t.string      :description
    end
  end
end
class CreateItems < ActiveRecord::Migration
  def change
    create_table :items do |t|
      t.string        :description
      t.boolean       :visible
      t.integer       :category_id
      t.integer       :user_id
    end
  end
end
class CreateRatings < ActiveRecord::Migration
  def change
    create_table :ratings do |t|
      t.integer         :value
      t.datetime        :ratingdate
      t.references      :rateable, :polymorphic => true
      t.integer         :createdby
    end
  end
end
class AddGuidToItem < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.string        :itemguid
    end
  end
end
class AddItemSavedToItem < ActiveRecord::Migration
  def change
    change_table :items do |t|
      t.boolean         :itemsaved
    end
  end
end
class CreateNews < ActiveRecord::Migration
  def change
    create_table :news do |t|
      t.string          :description
      t.datetime        :date
      t.string          :link
    end
  end
end
class CreateNominations < ActiveRecord::Migration
  def change
    create_table :nominations do |t|
      t.integer         :item_id
      t.integer         :user_id
      t.integer         :month
      t.boolean         :finished
    end
  end
end
class CreateVotes < ActiveRecord::Migration
  def change
    create_table :votes do |t|
      t.integer         :user_id
      t.integer         :nomination_id
      t.datetime        :date
    end
  end
end
# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120507041001) do

  create_table "categories", :force => true do |t|
    t.string "description"
  end

  create_table "images", :force => true do |t|
    t.string  "filename"
    t.string  "content_type"
    t.binary  "binary_data"
    t.integer "imageable_id"
    t.string  "imageable_type"
    t.string  "imageguid"
  end

  create_table "items", :force => true do |t|
    t.string  "description"
    t.boolean "visible"
    t.integer "category_id"
    t.integer "user_id"
    t.string  "itemguid"
    t.boolean "itemsaved"
  end

  create_table "news", :force => true do |t|
    t.string   "description"
    t.datetime "date"
    t.string   "link"
  end

  create_table "nominations", :force => true do |t|
    t.integer "item_id"
    t.integer "user_id"
    t.integer "month"
    t.boolean "finished"
  end

  create_table "ratings", :force => true do |t|
    t.integer  "value"
    t.datetime "ratingdate"
    t.integer  "rateable_id"
    t.string   "rateable_type"
    t.integer  "createdby"
  end

  create_table "users", :force => true do |t|
    t.string   "username"
    t.string   "password_hash"
    t.string   "userid"
    t.boolean  "verified"
    t.string   "verifyguid"
    t.datetime "membersince"
    t.string   "email"
    t.string   "userguid"
  end

  create_table "votes", :force => true do |t|
    t.integer  "user_id"
    t.integer  "nomination_id"
    t.datetime "date"
  end

end
# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)
require 'test_helper'

class AccessControllerTest < ActionController::TestCase
  test "should get authenticate" do
    get :authenticate
    assert_response :success
  end

end
require 'test_helper'

class ImageControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class ImagecontrollerControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class IotmControllerTest < ActionController::TestCase
  test "should get list" do
    get :list
    assert_response :success
  end

  test "should get previous" do
    get :previous
    assert_response :success
  end

end
require 'test_helper'

class ItemControllerTest < ActionController::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class UserControllerTest < ActionController::TestCase
  test "should get authenticate" do
    get :authenticate
    assert_response :success
  end

end
require 'test_helper'

class UserMailerTest < ActionMailer::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class WelcomeControllerTest < ActionController::TestCase
  test "should get index" do
    get :index
    assert_response :success
  end

end
require 'test_helper'
require 'rails/performance_test_help'

class BrowsingTest < ActionDispatch::PerformanceTest
  # Refer to the documentation for all available options
  # self.profile_options = { :runs => 5, :metrics => [:wall_time, :memory]
  #                          :output => 'tmp/performance', :formats => [:flat] }

  def test_homepage
    get '/'
  end
end
ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
require 'test_helper'

class CategoryTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class AccessHelperTest < ActionView::TestCase
end
require 'test_helper'

class ImageHelperTest < ActionView::TestCase
end
require 'test_helper'

class ImagecontrollerHelperTest < ActionView::TestCase
end
require 'test_helper'

class IotmHelperTest < ActionView::TestCase
end
require 'test_helper'

class ItemHelperTest < ActionView::TestCase
end
require 'test_helper'

class UserHelperTest < ActionView::TestCase
end
require 'test_helper'

class WelcomeHelperTest < ActionView::TestCase
end
require 'test_helper'

class ImageTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class ItemTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class LoginTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class NewsTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class NominationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class RatingTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class UploadsTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
require 'test_helper'

class VoteTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
