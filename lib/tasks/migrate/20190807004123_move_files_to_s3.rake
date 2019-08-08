namespace :check do
  namespace :migrate do
    task move_files_to_s3: :environment do
      s3 = Rails.cache.read('check:migrate:s3')
      raise "Nothing found in cache for key check:migrate:s3! Aborting." if s3.nil?
      puts "[#{Time.now}] Calculating number of files to be migrated to S3..."
      root = File.join(Rails.root, 'public')
      n = 0
      Dir.glob("#{root}/uploads/**/*").select do |f|
        n += 1 if File.file?(f)
      end
      puts "[#{Time.now}] Moving #{n} files to S3..."
      i = 0
      Dir.glob("#{root}/uploads/**/*").select do |f|
        if File.file?(f)
          i += 1
          path = f.gsub(/^#{root}\//, '')
          type = MIME::Types.type_for(f).first.content_type
          CheckS3.write(path, type, File.read(f))
          print "#{i}/#{n}\r"
          $stdout.flush
        end
      end
      puts
      puts "[#{Time.now}] Done!"
      # Rails.cache.delete('check:migrate:s3')
    end
  end
end
