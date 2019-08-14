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
      j = 0
      k = 0
      Dir.glob("#{root}/uploads/**/*").select do |f|
        if File.file?(f)
          i += 1
          path = f.gsub(/^#{root}\//, '')
          type = MIME::Types.type_for(f).first.content_type
          content = File.read(f)
          if CheckS3.exist?(path) && CheckS3.get(path).etag.gsub('"', '') === Digest::MD5.hexdigest(content)
            k += 1
          else
            CheckS3.write(path, type, content)
            j += 1
          end
          print "#{i} processed, #{j} uploaded, #{k} skipped, #{n} total\r"
          $stdout.flush
        end
      end
      puts
      puts "[#{Time.now}] Done!"
    end
  end
end
