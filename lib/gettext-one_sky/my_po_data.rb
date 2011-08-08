module GetText
  module OneSky
    class MyPoData < GetText::RMsgMerge::PoData
      
      def generate_po_entry(msgid)
        str = ""
        str << @msgid2comment[msgid]
        if str[-1] != "\n"[0]
          str << "\n"
        end

        id = msgid.gsub(/"/, '\"').gsub(/\r/, '')
        msgstr = @msgid2msgstr[msgid].gsub(/"/, '\"').gsub(/\r/, '')

# MONKEY PATCHING START
        if id.include?("\004")
          ids = id.split(/\004/)
          context = ids[0]
          id      = ids[1]
          str << "msgctxt "  << __conv(context) << "\n"
        end
# MONKEY PATCHING END

        if id.include?("\000")
          ids = id.split(/\000/)
          str << "msgid " << __conv(ids[0]) << "\n"
          ids[1..-1].each do |single_id|
            str << "msgid_plural " << __conv(single_id) << "\n"
          end

          msgstr.split("\000").each_with_index do |m, n|
            str << "msgstr[#{n}] " << __conv(m) << "\n"
          end
        else
          str << "msgid "  << __conv(id) << "\n"
          str << "msgstr " << __conv(msgstr) << "\n"
        end

        str << "\n"
        str
      end
    end
  end
end