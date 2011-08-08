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
        
        Dir.glob("#{po_dir_path(path)}/**/*.pot").each do |file_path|
          @phrases_flat += parse_phrase_file(file_path)
        end
      end
      
      # Upload phrases to Onesky server
      def upload_phrases(path = nil)
        load_phrases(path) unless @phrases_flat

        @project.input_bulk(@phrases_flat, :page => @phrases_flat.first[:page])
      end
      
      # Parse and load translated phrases from .po files
      # If not a Rails project, manually supply the path where the .po file path located.
      def load_translations(path=nil)
        @translations_flat = []
        
        Dir.glob("#{po_dir_path(path)}/**/*.po").each do |file_path|
          lang_code = File.dirname(file_path).split("/").last
          
          @translations_flat += parse_phrase_file(file_path, lang_code)
        end
      end

      # Upload translated phrases to Onesky server
      def upload_translations(path=nil)
        load_translations(path) unless @translations_flat

        @translations_flat.each do |values|
          @project.send(:post, "/string/translate", values)
        end
      end

      # Download all available translations from Onesky server
      def download_translations
        @translations_from_onesky = @project.output
      end
      
      # Download all available translations from Onesky server and save them as *.po files.
      def save_translations(path=nil)
        download_translations unless @translations_from_onesky
        
        update_translation_files_from_onesky(po_dir_path(path), @translations_from_onesky)
      end



      protected
      
      def default_options
        if defined? Rails
          YAML.load_file([Rails.root.to_s, 'config', 'one_sky.yml'].join('/')).symbolize_keys
        else
          {:api_key => ENV["ONESKY_API_KEY"], :api_secret => ENV["ONESKY_API_SECRET"], :project => ENV["ONESKY_PROJECT"]}
        end
      end
      
      def po_dir_path(path)
        if defined? Rails
          path ||= [Rails.root.to_s, "po"].join("/")
        else
          raise ArgumentError, "Please supply the po directory path where locale files are to be downloaded." unless path && File.directory?(path)
          path = path.chop if path =~ /\/$/
        end
        
        path
      end
      
      def update_translation_files_from_onesky(po_dir_path, translations)
        # Delete all existing one_sky translation files before downloading a new set.
        File.delete(*Dir.glob("#{po_dir_path}/**/*.po_from_one_sky"))
        
        # Process each locale and save to file
        translations.each_pair do |text_domain, values|
          file_name = text_domain.gsub(/\.po$/, '')
          pot_file_path = [po_dir_path, file_name + ".pot"].join('/')
          
          values.each_pair do |lang_code, translated_phrases|
            language_dir = "#{po_dir_path}/#{lang_code}"
            Dir.mkdir(language_dir) unless File.exists?(language_dir)
            po_from_one_sky_file = "#{language_dir}/#{file_name}.po_from_one_sky"
            
            save_locale(pot_file_path, po_from_one_sky_file, lang_code, translated_phrases)
          end
        end
      end

      def save_locale(pot_file_path, po_file_name, lang_code, new_phrases)
        my_po_parser = GetText::OneSky::MyPoParser.new
        updated_phrases = my_po_parser.from_onesky_format(pot_file_path, new_phrases)
        updated_phrases.set_comment(:last, "# END")
        
        lang = @one_sky_languages.find { |e| e["locale"] == lang_code }

        File.open(po_file_name, 'w') do |f|
          f.print onesky_header(lang)
          f.print updated_phrases.generate_po
        end
        po_file_name
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

