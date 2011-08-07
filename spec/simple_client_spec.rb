require 'helpers'

describe "SimpleClient" do
  it "raises an error when initialization values are nil." do
    lambda { @client = GetText::OneSky::SimpleClient.new(:api_key => nil, :api_secret => nil, :project => nil) }.should raise_error ArgumentError
  end
end

describe "SimpleClient" do
  include GetTextOneSkySpecHelpers

  before(:all) do
    @project = create_simple_project
    delete_onesky_project(@project)
    create_onesky_project(@project)

    @client = create_simple_client_and_load
  end
   
  describe "#load_phrases" do
    it "should load flattened phrases." do
      expected = [{:"string-key"=>"Hello", :page=>"simple_client.po", :string=>"Hello", :translation=>""},
       {:"string-key"=>"Stock", :page=>"simple_client.po", :string=>"Stock", :context=>"Singular", :translation=>""},
       {:"string-key"=>"Stocks", :page=>"simple_client.po", :string=>"Stocks", :context=>"Plural", :translation=>""},
       # {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"General", :translation=>""},
       {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Long", :translation=>""},
       {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Short", :translation=>""},
       {:"string-key"=>"Should upload this phrase without context", :page=>"simple_client.po", :string=>"Should upload this phrase without context", :context=>"Singular", :translation=>""},
       {:"string-key"=>"Should upload this phrase without context", :page=>"simple_client.po", :string=>"Should upload this phrase without context", :context=>"Plural", :translation=>""}]
       
      @client.phrases_flat.should == expected
    end
  end
  
  describe "#upload_phrases" do
    it "returns true." do
      @client.upload_phrases.should be_true
    end
  end
  
  describe "#load_translations" do
    it "should load flattened translations." do
      expected = { "en_US" => 
        [{:"string-key"=>"Hello", :page=>"simple_client.po", :string=>"Hello", :translation=>"Updated Hello Plain"},
         {:"string-key"=>"Stock", :page=>"simple_client.po", :string=>"Stock", :context=>"Singular", :translation=>"Updated Singular Stock"},
         {:"string-key"=>"Stocks", :page=>"simple_client.po", :string=>"Stocks", :context=>"Plural", :translation=>"Updated Plural Stocks"},
         # {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"General", :translation=>"Time to enter order"},
         {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Long", :translation=>"Updated Expect it to raise. Time to enter order"},
         {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Short", :translation=>"Updated Expect it to drop. Time to enter order"},
         {:"string-key"=>"Should upload this phrase without context", :page=>"simple_client.po", :string=>"Should upload this phrase without context", :context=>"Singular", :translation=>"Updated CONTEXT AND SING"},
         {:"string-key"=>"Should upload this phrase without context", :page=>"simple_client.po", :string=>"Should upload this phrase without context", :context=>"Plural", :translation=>"Updated CONTEXT AND PLURAL"}]
       }
  
      @client.translations_flat.should == expected
    end
  end
  
  # describe "#upload_translations" do
  #   it "returns true." do
  #     @client.upload_translations.should be_true
  #   end
  # end
  # 
  # describe "#download_translations" do
  #   po_dir_path = [File.dirname(__FILE__), 'po'].join('/')
  #   pot_file_path = [File.dirname(__FILE__), "po", "simple_client.pot"].join('/')
  # 
  #   it "saves translation files." do
  #     @client.download_translations(po_dir_path, pot_file_path).should be_a_kind_of Array
  #     Dir.glob("#{po_dir_path}/**/simple_client.po_from_one_sky").size.should >= 1
  #   end
  # end
end
