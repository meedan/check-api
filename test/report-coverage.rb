require 'json'
input = ARGV.last
if File.exist?(input)
  json = JSON.parse(File.read(input))
  puts "Coverage: #{json['covered_percent']}% (#{json['line_counts']['covered']}/#{json['line_counts']['total']} lines covered, #{json['line_counts']['missed']} missing)"
  json['source_files'].each do |file|
    if file['covered_percent'] < 100
      lines = []
      i = 0
      JSON.parse(file['coverage']).each do |value|
        i += 1
        lines << i if value == 0
      end
      puts "#{file['name'].gsub(/^.*check-api\//, '')}: #{file['covered_percent']}% (#{file['line_counts']['covered']}/#{file['line_counts']['total']} lines covered, #{file['line_counts']['missed']} missing: #{lines.join(', ')})"
    end
  end
  if json['line_counts']['missed'] > 0
    exit 1
  else
    exit 0
  end
else
  puts 'Nothing here, please check the other build.'
  exit 0
end
