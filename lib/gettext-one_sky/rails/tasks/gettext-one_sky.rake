namespace :one_sky do
  desc "Upload phrases for translation to OneSky."
  task :upload_phrases => :environment do
    client = GetText::OneSky::SimpleClient.new
    puts client.load_phrases
    client.upload_phrases
    puts "Phrases uploaded to OneSky. Please ask your translators to... well... get translating."
  end

  desc "Upload translated phrases to OneSky."
  task :upload_translated_phrases => :environment do
    client = GetText::OneSky::SimpleClient.new
    puts client.load_translations
    client.upload_translations
    puts "Translated phrases uploaded to OneSky."
  end

  desc "Download available translations from OneSky."
  task :download_translations do
    client = GetText::OneSky::SimpleClient.new
    client.download_translations
    puts "Translations downloaded and saved to po/**/*_one_sky.po files."
  end
end
