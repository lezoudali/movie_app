require 'bundler/setup'
Bundler.require(:default, :development)
$: << '.'

require 'open-uri'
require 'uri'
require "json"

Dir["app/concerns/*.rb"].each {|f| require f}
Dir["app/data_fetchers/*.rb"].each {|f| require f}
Dir["app/models/*.rb"].each {|f| require f}
Dir["app/runners/*.rb"].each {|f| require f}



