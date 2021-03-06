require 'sinatra'
require 'dalli'
require 'json'
require 'rest_client'
require 'date'
require 'sinatra/base'
require 'mustache/sinatra'
require 'resque'
require 'user_agent'


base_path = File.join(File.dirname(__FILE__))

require File.join(base_path, 'config.rb')
require File.join(base_path, 'models', 'status.rb')
require File.join(base_path, 'models', 'trains.rb')
require File.join(base_path, 'tasks', 'stats_job.rb')

client        = MongoClient.new('localhost', 27017)
DB            = client['pnrapi']
TWO_WEEKS     = 1209600
HALF_DAY      = 43200
PNR_CACHE_KEY = "pnr:%s"


set :public_folder, File.dirname(__FILE__) + '/public'

Sinatra.register Mustache::Sinatra

class App < Sinatra::Base
  require './views/layout.rb'

  configure do
    register Mustache::Sinatra
    set :environment, :development
    set :cache, Dalli::Client.new
    set :mustache, {
      :views     => './views',
      :templates => './templates'
    }
  end


  get '/' do
    @title = "Mustache + Sinatra = Wonder"
    mustache 'index'
  end

  get '/test' do
  end

  get '/api/v1.0/pnr/:pnr' do
    start_t = Time.now
    jsonp = params.fetch 'jsonp', nil
    pnr   = params.fetch 'pnr'

    content_type 'application/json'
    cache_key = PNR_CACHE_KEY % (pnr)

    data = settings.cache.get(PNR_CACHE_KEY)

    if not data
      data = Status.fetch(pnr)
    end


    if jsonp
      "#{jsonp}(#{data.to_json})"
    else
      "#{data.to_json}"
    end
  end
end
