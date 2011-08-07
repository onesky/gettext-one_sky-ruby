require 'gettext/tools/poparser'
require 'gettext/tools/rmsgmerge'

module GetText
  module OneSky
    class MyPoParser < GetText::PoParser
      # override to include blank trsanslation messages
      def on_message(msgid, msgstr)
        @data[msgid] = msgstr
        @data.set_comment(msgid, @comments.join("\n"))

        @comments.clear
        @msgctxt = ""
      end
      
      def parse_po_file(path, lang_code=nil)
        gettext_formatted_messages = self.parse_file(path, GetText::RMsgMerge::PoData.new, false)
        
        page_name = File.basename(path).gsub(/.pot$/, '.po')
        to_onesky_format(gettext_formatted_messages, page_name, lang_code)
      end

      protected
      
      def to_onesky_format(messages, file_name, lang_code=nil)
        slices = []
        lang_options = Hash.new
        lang_options[:language] = lang_code if lang_code
        
        messages.each_msgid do |full_msg_id|
          msg_id = full_msg_id
          msg_str = messages.msgstr(msg_id)
          
          components = Hash.new
          if msg_id.include? "\004"
            msg_context, msg_id = msg_id.split(/\004/)
            components[:context] = msg_context
          end
          
          if msg_id.include? "\000"
            msg_singular, msg_plural = msg_id.split(/\000/)
            trans_singular, trans_plural = msg_str.split(/\000/)

            slices << {:context => "Singular", :string => msg_singular, :"string-key" => msg_singular, :page => file_name, :translation => trans_singular || ""}.merge(lang_options)
            slices << {:context => "Plural",   :string => msg_plural,   :"string-key" => msg_plural,   :page => file_name, :translation => trans_plural || ""}.merge(lang_options)
          else
            slices << components.merge(:string => msg_id, :"string-key" => msg_id, :translation => msg_str, :page => file_name).merge(lang_options)
          end
        end
        
        assign_general_context(slices)
        
        slices
      end
      
      def assign_general_context(slices)
        general_slices = slices.select{|slice| !slice.has_key?(:context)}
        general_slices.each do |general_slice|
          if slices.select{|slice| slice[:string] == general_slice[:string] && slice.has_key?(:context)}.any?
            general_slice[:context] = "General"
          end
        end
      end
    end
  end
end