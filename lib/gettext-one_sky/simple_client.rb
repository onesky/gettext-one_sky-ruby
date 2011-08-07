require 'gettext-one_sky/my_po_parser'

module GetText
  module OneSky

=begin
  This class is the bridge between the OneSky service and the gettext file storgage.
  It takes the phrases defined in gettext's default locale and uploads them to OneSky for translation.
  Then it downloads available translations and saves them as .po files.
  
  A regular workflow would then look like:
    initialize -> load_phrases -> upload_phrases -> download_translations

  
  * Initilaize *
  
  When you initialize a client inside a Rails project, 
  it will take the OneSky configuration variables supplied when you called rails generate one_sky:init.
  
  When you use this client outside of Rails,
  credentials are expected to come from environment variables: ONESKY_API_KEY, ONESKY_API_SECRET, ONESKY_PROJECT.
  You can override these defaults by providing a hash of options:
    {:api_key => ..., :api_secret => ..., :project => ...}
    
=end
    class SimpleClient
      attr_reader :phrases_nested, :phrases_flat, :translations_flat, :translations_from_onesky
      # The base OneSky project. Gives you low-level access to the API gem.
      attr_reader :project

      def initialize(options = {})
        options = default_options.merge!(options)
        @project = ::OneSky::Project.new(options[:api_key], options[:api_secret], options[:project])
        @one_sky_locale = @project.details["base_locale"]
        @one_sky_languages = @project.languages
      end

      # Parse and load phrases from .pot file.
      # If not a Rails project, manually supply the path where the .pot file located.
      def load_phrases(path=nil)
        @phrases_flat = []
        
        if defined? Rails
          Dir.glob("#{po_dir_path}/**/*.pot").each do |file_path|
            @phrases_flat += parse_phrase_file(file_path)
          end
        else
          raise ArgumentError, "Please supply the .pot file path." unless path
          @phrases_flat += parse_phrase_file(path)
        end
      end
      
      # Upload phrases to Onesky server
      def upload_phrases(path = nil)
        load_phrases(path) unless @phrases_flat

        @project.input_bulk(@phrases_flat)
      end
      
      # Parse and load translated phrases from .po files
      # If not a Rails project, manually supply the path where the .po file path located.
      def load_translations(path=nil)
        @translations_flat = []
        
        if defined? Rails
          Dir.glob("#{po_dir_path}/**/*.po").each do |file_path|
            lang_code = File.dirname(file_path).split("/").last
            
            @translations_flat += parse_phrase_file(path, lang_code)
            # @translations_flat += phrases.map do |phrase|
            #   phrase.merge(:language => lang_code)
            # end
          end
        else
          raise ArgumentError, "Please supply the .po file path." unless path
          lang_code = File.dirname(path).split("/").last
            
          @translations_flat += parse_phrase_file(path, lang_code)
          # @translations_flat += phrases.map do |phrase|
          #   phrase.merge(:language => lang_code)
          # end
        end
      end

      # Upload translated phrases to Onesky server
      def upload_translations(path=nil)
        load_translations(path) unless @translations_flat

        @translations_flat.each do |values|
          @project.send(:post, "/string/translate", values)
        end
      end

      # Download all available translations from Onesky server and save them as *.po files.
      # Outside of Rails, manually supply the path where downloaded files should be saved.
      def download_translations(pot_file_path=nil)
        @translations_from_onesky = []
        
        if defined? Rails
          Dir.glob("#{po_dir_path}/**/*.pot").each do |file_path|
            @translations_from_onesky += parse_project_output(file_path)
          end
        else
          raise ArgumentError, "Please supply the .pot file path." unless pot_file_path
          @translations_from_onesky += parse_project_output(pot_file_path)
        end
      end

      def save_translations(pot_file_path=nil)
        download_translations(pot_file_path) unless @translations_from_onesky
        
        update_translation_files(pot_file_path, @translations)
      end

      protected
      
      def default_options
        if defined? Rails
          YAML.load_file([Rails.root.to_s, 'config', 'one_sky.yml'].join('/')).symbolize_keys
        else
          {:api_key => ENV["ONESKY_API_KEY"], :api_secret => ENV["ONESKY_API_SECRET"], :project => ENV["ONESKY_PROJECT"]}
        end
      end
      
      def po_dir_path
        if defined? Rails
          path ||= [Rails.root.to_s, "po"].join("/")
        else
          raise ArgumentError, "Please supply the po directory path where locale files are to be downloaded." unless path
          path = path.chop if path =~ /\/$/
        end
        
        path
      end
      
      # TODO either use the provided pot to find available translation from ONESKY
      # TODO use the page parameter from ONESKY response to locate .pot and language folders
      def parse_project_output(pot_file_path)
        page_name = File.basename(pot_file_path).gsub(/.pot$/, '.po')
        output = @project.output(:page => page_name)
                
        # Let's ignore other hash nodes from the API and just rely on the string keys we sent during upload. Prefix with locale.
        result = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }

        # 
        # output.map do |k0,v0| # Page level
        #   v0.map do |k1, v1| # Locale level
        #     v1.map do |k2, v2| # string key level
        #       result[k0][k1][k2] = v2 
        #     end
        #   end 
        # end
        
        []
      end
      
      def update_translation_files(pot_file_path, translations)
        # Delete all existing one_sky translation files before downloading a new set.
        File.delete(*Dir.glob("#{po_dir_path}/**/*.po_from_one_sky"))
        
        # Process each locale and save to file
        translations.map { |k,v|
          parent_dir = "#{po_dir_path}/#{k}"
          
          Dir.mkdir(parent_dir) unless File.exists?(parent_dir)
          save_locale(pot_file_path, "#{parent_dir}/#{page_name}.po_from_one_sky", k, v)
        }
      end

      def save_locale(pot_file_path, po_filename, lang_code, new_phrases)
        original_phrases = parse_phrase_file(pot_file_path)
        new_phrases.each do |key, value|
          original_phrases[key] = value
          original_phrases.set_comment(key, "")
        end
        original_phrases.set_comment(:last, "# END")
        
        lang = @one_sky_languages.find { |e| e["locale"] == lang_code }

        File.open(po_filename, 'w') do |f|
          f.print onesky_header(lang)
          f.print original_phrases.generate_po
        end
        po_filename
      end
      
      def onesky_header(lang)
        "# PLEASE DO NOT EDIT THIS FILE.\n" +
        "# This was downloaded from OneSky. Log in to your OneSky account to manage translations on their website.\n" +
        "# Language code: #{lang['locale']}\n" +
        "# Language name: #{lang['locale_name']}\n" +
        "# Language English name: #{lang['eng_name']}\n" +
        "#\n"
        "#\n"
      end
      
      def parse_translated_file(path=nil)
        if defined? Rails
          path ||= File.join(RAILS_ROOT, '/po', "**/*.po")
        else
          raise ArgumentError, "Please supply the path where the .po file is located." unless path
          path = path.chop if path =~ /\/$/
        end

        parser = GetText::OneSky::MyPoParser.new
        parser.parse_po_file(path)        
      end
      
      def parse_phrase_file(path=nil, lang_code=nil)
        raise ArgumentError, "Please supply the path where the .pot file is located." unless path
        
        parser = GetText::OneSky::MyPoParser.new
        parser.parse_po_file(path, lang_code)
      end
    end
  end
end

