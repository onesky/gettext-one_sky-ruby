namespace :one_sky do
  desc "Upload phrases (.pot files) for translation to OneSky."
  task :upload_phrases => :environment do
    client = GetText::OneSky::SimpleClient.new
    puts client.load_phrases
    client.upload_phrases
    puts "Phrases uploaded to OneSky. Please ask your translators to... well... get translating."
  end

  desc "Upload translated phrases (.po files) to OneSky."
  task :upload_translated_phrases => :environment do
    client = GetText::OneSky::SimpleClient.new
    puts client.load_translations
    client.upload_translations
    puts "Translated phrases uploaded to OneSky."
  end

  desc "Download available translations from OneSky and save as .po_from_one_sky."
  task :download_translations do
    client = GetText::OneSky::SimpleClient.new
    client.download_translations
    puts "Translations downloaded and saved to po/**/*.po_from_one_sky files."
  end
end
