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
      
      def parse_po_file(path)
        gettext_formatted_messages = self.parse_file(path, GetText::RMsgMerge::PoData.new, false)
        
        page_name = File.basename(path).gsub(/.pot$/, '.po')
        to_onesky_format(gettext_formatted_messages, page_name)
      end

      protected
      
      def to_onesky_format(messages, file_name)
        slices = []
        
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

            slices << {:context => "Singular", :string => msg_singular, :string_key => msg_singular, :page => file_name, :translation => trans_singular || ""}
            slices << {:context => "Plural",   :string => msg_plural,   :string_key => msg_plural,   :page => file_name, :translation => trans_plural || ""}
          else
            slices << components.merge(:string => msg_id, :string_key => msg_id, :translation => msg_str, :page => file_name)
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