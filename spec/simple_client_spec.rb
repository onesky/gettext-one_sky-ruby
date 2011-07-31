require 'helpers'

describe "SimpleClient" do
  it "raises an error when initialization values are nil." do
    lambda { @client = GetText::OneSky::SimpleClient.new(:api_key => nil, :api_secret => nil, :project => nil) }.should raise_error ArgumentError
  end
end

describe "SimpleClient" do
  include GetTextOneSkySpecHelpers

  before do
    @client = create_simple_client_and_load
  end

  describe "#load_phrases" do
    it "should load flattened phrases." do
      @client.phrases_flat["Hello"].should == ""
    end
  end
  
  describe "#load_translations" do
    it "should load flattened translations." do
      # @client.translations["Hello"].should == "Too"
    end
  end

  describe "#upload_phrases" do
    it "returns true." do
      @client.upload_phrases.should be_true
    end
  end
  
  describe "#upload_translations" do
    it "returns true" do
      # @client.upload_transalcations.should be_true
    end
  end
end

describe "SimpleClient" do
  include GetTextOneSkySpecHelpers

  before do
    @client = create_simple_client
  end

  describe "#download_translations" do
    po_dir_path = [File.dirname(__FILE__), 'po'].join('/')
    pot_file_path = [File.dirname(__FILE__), "po", "simple_client.pot"].join('/')
    
    it "saves translation files." do
      @client.download_translations(po_dir_path, pot_file_path).should be_a_kind_of Array
      Dir.glob("#{po_dir_path}/**/from_one_sky.po").size.should >= 1
    end
  end
end

