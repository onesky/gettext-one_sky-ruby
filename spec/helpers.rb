$:.unshift File.expand_path('..', __FILE__)
$:.unshift File.expand_path('../../lib', __FILE__)

require 'gettext-one_sky'

module GetTextOneSkySpecHelpers
  def create_simple_client
    raise "Please set environment variables: ONESKY_API_KEY, ONESKY_API_SECRET and ONESKY_SPEC_PROJ (default: gettextoneskyspec) before running spec." unless [ENV["ONESKY_API_KEY"], ENV["ONESKY_API_SECRET"]].all?
    GetText.locale = "en_US"
    client = GetText::OneSky::SimpleClient.new(options)
  end
  
  def create_simple_project
    OneSky::Project.new(options[:api_key], options[:api_secret], options[:project])
  end

  def create_simple_client_and_load
    client = create_simple_client
    
    load_phrases(client)
    
    client
  end
  
  def delete_onesky_project(project)
    begin
      project.send(:post, "/project/delete", {:project => test_project_code})
    rescue RestClient::BadRequest
      retry
    rescue OneSky::ApiError
    end
  end
  
  def create_onesky_project(project)
    project.send(:post, "/project/add", {:project => test_project_code, :type => "ruby", :"base-language-code" => "en_US"})
  end

  protected
  
  def load_phrases(client)
    Dir.glob("#{po_dir_path}/**/*.pot").each do |file_path|
      client.load_phrases(file_path)
    end
  end
  
  def load_translations(client)
    Dir.glob("#{po_dir_path}/**/*.po").each do |file_path|
      client.load_translations(file_path)
    end
  end
  
  def po_dir_path
    [File.dirname(__FILE__), "po"].join("/")
  end
  
  # hopefully not accidentally delete other real translation project
  def test_project_code
    "ONESKY_TEST_#{ENV["ONESKY_SPEC_PROJ"]}"
  end
  
  def options
    {
      :api_key => ENV["ONESKY_API_KEY"], 
      :api_secret => ENV["ONESKY_API_SECRET"], 
      :project => test_project_code || "gettextoneskyspec"
    }
  end
end
