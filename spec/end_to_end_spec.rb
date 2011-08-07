require 'helpers'

describe "SimpleClient End 2 End workflow" do
  include GetTextOneSkySpecHelpers

  before do
    delete_onesky_project
    create_onesky_project
    
    @client = create_simple_client_and_load
  end

  describe "#upload_phrases" do
    it "" do
      @client.upload_phrases
      @client.upload_transalcations
    
      po_dir_path = [File.dirname(__FILE__), 'po'].join('/')
      pot_file_path = [File.dirname(__FILE__), "po", "simple_client.pot"].join('/')
    
      @client.download_translations(po_dir_path, pot_file_path).should be_a_kind_of Array
      Dir.glob("#{po_dir_path}/**/from_one_sky.po").size.should >= 1
      
      @client.translations["Hello"].should == "Too"
    end
  end
end
