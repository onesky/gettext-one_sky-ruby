$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'gettext-one_sky'

module GetTextOneSkySpecHelpers
  def create_simple_client
    raise "Please set environment variables: ONESKY_API_KEY, ONESKY_API_SECRET and ONESKY_SPEC_PROJ (default: gettextoneskyspec) before running spec." unless [ENV["ONESKY_API_KEY"], ENV["ONESKY_API_SECRET"]].all?
    GetText.locale = "en_US"
    client = GetText::OneSky::SimpleClient.new(
      :api_key => ENV["ONESKY_API_KEY"], 
      :api_secret => ENV["ONESKY_API_SECRET"], 
      :project => ENV["ONESKY_SPEC_PROJ"] || "gettextoneskyspec"
    )
  end

  def create_simple_client_and_load
    client = create_simple_client
    client.load_phrases([File.dirname(__FILE__), "po", "simple_client.pot"].join('/'))
    # client.load_translations([File.dirname(__FILE__), "po", "en", "simple_client.po"].join('/'))
    client 
  end  
end
