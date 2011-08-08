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
    
    @pot_file_path = [File.dirname(__FILE__), "po"].join('/')
  end
  
  before do
    @client = create_simple_client_and_load
  end
   
  describe "project with phrases inside .pot file" do
    describe "#load_phrases" do
      it "should load flattened phrases." do
        expected = [{:"string-key"=>"Hello", :page=>"simple_client.po", :string=>"Hello", :translation=>""},
         {:"string-key"=>"Stock", :page=>"simple_client.po", :string=>"Stock", :context=>"Singular", :translation=>""},
         {:"string-key"=>"Stocks", :page=>"simple_client.po", :string=>"Stocks", :context=>"Plural", :translation=>""},
         {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"General", :translation=>""},
         {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Long", :translation=>""},
         {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Short", :translation=>""},
         {:"string-key"=>"Should upload this singular phrase without context", :page=>"simple_client.po", :string=>"Should upload this singular phrase without context", :context=>"Singular", :translation=>""},
         {:"string-key"=>"Should upload this plural phrase without context", :page=>"simple_client.po", :string=>"Should upload this plural phrase without context", :context=>"Plural", :translation=>""}]
       
        @client.phrases_flat.should == expected
      end
    end
    
    describe "Translation output from Onesky" do
      before do
        @client.upload_phrases.should be_true
        @client.download_translations
      end
  
      describe "#download_translations" do      
        it "transforms translation result from Onesky" do
          expected = { "simple_client.po" =>        
            {"en_US"=>
              {"Good to Enter"=>
                 {"General" => "Good to Enter", "Short"=>"Good to Enter", "Long"=>"Good to Enter"}, 
               "Stock"=>
                 {"Singular"=>"Stock"},
               "Should upload this singular phrase without context"=>
                 {"Singular"=>"Should upload this singular phrase without context"},
               "Should upload this plural phrase without context"=>
                 {"Plural"=>"Should upload this plural phrase without context"}, 
               "Hello"=>"Hello",
               "Stocks"=>
                 {"Plural"=>"Stocks"}
              }
            }
          }
        
          @client.translations_from_onesky.should == expected
        end
      end
      
      describe "#save_translations" do
        it "saves the translation into .po files of all available languages." do
          @client.save_translations(@pot_file_path)
  
          Dir.glob("#{po_dir_path}/**/simple_client.po_from_one_sky").size.should >= 1
        end
      end
    end
  end
  
  describe "with translated .po files" do
    before do
      load_translations(@client)
    end
    
    describe "#load_translations" do
      it "should load flattened translations." do
        expected = 
          [{:"string-key"=>"Hello", :page=>"simple_client.po", :string=>"Hello", :translation=>"Updated Hello Plain", :language => "en_US"},
           {:"string-key"=>"Stock", :page=>"simple_client.po", :string=>"Stock", :context=>"Singular", :translation=>"Updated Singular Stock", :language => "en_US"},
           {:"string-key"=>"Stocks", :page=>"simple_client.po", :string=>"Stocks", :context=>"Plural", :translation=>"Updated Plural Stocks", :language => "en_US"},
           {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"General", :translation=>"Updated Time to enter order", :language => "en_US"},
           {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Long", :translation=>"Updated Expect it to raise. Time to enter order", :language => "en_US"},
           {:"string-key"=>"Good to Enter", :page=>"simple_client.po", :string=>"Good to Enter", :context=>"Short", :translation=>"Updated Expect it to drop. Time to enter order", :language => "en_US"},
           {:"string-key"=>"Should upload this singular phrase without context", :page=>"simple_client.po", :string=>"Should upload this singular phrase without context", :context=>"Singular", :translation=>"Updated CONTEXT AND SING", :language => "en_US"},
           {:"string-key"=>"Should upload this plural phrase without context", :page=>"simple_client.po", :string=>"Should upload this plural phrase without context", :context=>"Plural", :translation=>"Updated CONTEXT AND PLURAL", :language => "en_US"}]
  
        @client.translations_flat.should == expected
      end
    end
    
    describe "retrieving updated translation output from Onesky" do
      before do
        @client.upload_translations.should be_true
        @client.download_translations
      end

      ########
      #   this test case does not work, because the original translation is always the default values returned
      ########
            
      # describe "#download_translations" do      
      #   it "transforms updated translation result from Onesky" do
      #     expected = { "simple_client.po" =>        
      #       {"en_US"=>
      #         {"Good to Enter"=>
      #            {"General" => "Updated Time to enter order", "Short"=>"Updated Expect it to drop. Time to enter order", "Long"=>"Updated Expect it to raise. Time to enter order"}, 
      #          "Stock"=>
      #            {"Singular"=>"Updated Singular Stock"},
      #          "Should upload this singular phrase without context"=>
      #            {"Singular"=>"Updated CONTEXT AND SING"},
      #          "Should upload this plural phrase without context"=>
      #            {"Plural"=>"Updated CONTEXT AND PLURAL"}, 
      #          "Hello"=>"Updated Hello Plain",
      #          "Stocks"=>
      #            {"Plural"=>"Updated Plural Stocks"}
      #         }
      #       }
      #     }
      # 
      #     @client.translations_from_onesky.should == expected
      #   end
      # end
      #       
      # describe "#save_translations" do
      #   it "saves the updated translation into .po files of all available languages." do
      #     @client.save_translations(@pot_file_path)
      #   
      #     Dir.glob("#{po_dir_path}/**/simple_client.po_from_one_sky").size.should >= 1
      #   end
      # end
    end
  end
end
