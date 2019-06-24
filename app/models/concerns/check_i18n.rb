require 'active_support/concern'

module CheckI18n
  extend ActiveSupport::Concern

  module ClassMethods
    def convert_numbers(str)
      return nil if str.blank?
      altzeros = [0x0030, 0x0660, 0x06F0, 0x07C0, 0x0966, 0x09E6, 0x0A66, 0x0AE6, 0x0B66, 0x0BE6, 0x0C66, 0x0CE6, 0x0D66, 0x0DE6, 0x0E50, 0x0ED0, 0x0F20, 0x1040, 0x1090, 0x17E0, 0x1810, 0x1946, 0x19D0, 0x1A80, 0x1A90, 0x1B50, 0x1BB0, 0x1C40, 0x1C50, 0xA620, 0xA8D0, 0xA900, 0xA9D0, 0xA9F0, 0xAA50, 0xABF0, 0xFF10]
      digits = altzeros.flat_map { |z| ((z.chr(Encoding::UTF_8))..((z+9).chr(Encoding::UTF_8))).to_a }.join('')
      replacements = "0123456789" * altzeros.size
      str.tr(digits, replacements).to_i
    end

    def is_rtl_lang?
      rtl_lang = [
        'ae', 'ar',  'arc','bcc', 'bqi','ckb', 'dv','fa',
        'glk', 'he', 'ku', 'mzn','nqo', 'pnb','ps', 'sd', 'ug','ur','yi'
      ]
      rtl_lang.include?(I18n.locale.to_s) ? true : false
    end

  end
end
