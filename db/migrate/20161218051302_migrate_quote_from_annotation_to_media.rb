class MigrateQuoteFromAnnotationToMedia < ActiveRecord::Migration[4.2]
  def change
    Media.where(url: nil).each do |m|
      m.annotations('embed').each do |e|
        unless e.quote.nil?
          m.quote = e.quote
          m.save!
        end
      end
    end

  end
end
