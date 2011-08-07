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
      attr_reader :phrases_nested, :phrases_flat, :translations_flat
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
        path ||= pot_path
        @phrases_flat = parse_phrase_file(path)
      end
      
      def load_translations(path=nil)
        path ||= po_dir_path
        lang_code = File.dirname(path).split("/").last
        
        @translations_flat = Hash.new
        @translations_flat[lang_code] = parse_phrase_file(path)
      end
      
      # Upload phrases to Onesky server
      def upload_phrases
        load_phrases unless @phrases_flat

        @project.input_bulk(@phrases_flat)
      end

      # Upload translated phrases to Onesky server      
      def upload_translations
        load_translations unless @translations_flat

        @translations_flat.each_pair do |lang, values|
          values.each do |value|
            something = {:"string-key" => value[:"string-key"], :language => lang, :context => value[:context], :translation => value[:translation]}

            @project.send(:post, "/string/translate", {:"string-key" => value[:"string-key"], :language => lang, :context => value[:context], :translation => value[:translation]})
          end
        end
      end

      # Download all available translations from Onesky server and save them as *.po files.
      # Outside of Rails, manually supply the path where downloaded files should be saved.
      def download_translations(po_dir_path=nil, pot_file_path=nil)
        @translations = parse_project_output(@project.output)

        update_translation_files(po_dir_path, pot_file_path, @translations)
      end

      protected
      
      def default_options
        if defined? Rails
          YAML.load_file([Rails.root.to_s, 'config', 'one_sky.yml'].join('/')).symbolize_keys
        else
          {:api_key => ENV["ONESKY_API_KEY"], :api_secret => ENV["ONESKY_API_SECRET"], :project => ENV["ONESKY_PROJECT"]}
        end
      end

      def pot_file_path
        if defined? Rails
          pot_file_path ||= Dir.glob(File.join(RAILS_ROOT, "/po/**/*.pot")).first
        else
          raise ArgumentError, "Please supply the pot file path where locales are to be downloaded." unless pot_file_path
        end
      end
      
      def po_dir_path
        if defined? Rails
          po_dir_path ||= [Rails.root.to_s, "po"].join("/")
        else
          raise ArgumentError, "Please supply the po directory path where locales are to be downloaded." unless po_dir_path
          po_dir_path = po_dir_path.chop if po_dir_path =~ /\/$/
        end
      end
      
      def parse_project_output(output)
        # Let's ignore other hash nodes from the API and just rely on the string keys we sent during upload. Prefix with locale.
        result = Hash.new{ |h,k| h[k] = Hash.new(&h.default_proc) }
        output.map do |k0,v0| # Page level
          v0.map do |k1, v1| # Locale level
            v1.map do |k2, v2| # string key level
              result[k1][k2] = v2 
            end
          end 
        end
        result
      end
      
      def update_translation_files(po_dir_path, pot_file_path, translations)
        # Delete all existing one_sky translation files before downloading a new set.
        File.delete(*Dir.glob("#{po_dir_path}/**/from_one_sky.po"))
        
        # Process each locale and save to file
        translations.map { |k,v|
          parent_dir = "#{po_dir_path}/#{k}"
          
          Dir.mkdir(parent_dir) unless File.exists?(parent_dir)
          save_locale(pot_file_path, "#{parent_dir}/from_one_sky.po", k, v)
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
      
      def parse_phrase_file(path=nil)
        if defined? Rails
          path ||= File.join(RAILS_ROOT, '/po', "**/*.pot")
        else
          raise ArgumentError, "Please supply the path where the pot file is located." unless path
          path = path.chop if path =~ /\/$/
        end
        
        parser = GetText::OneSky::MyPoParser.new
        parser.parse_po_file(path)
      end
    end
  end
end

