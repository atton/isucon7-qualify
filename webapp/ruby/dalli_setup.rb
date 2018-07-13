require 'dalli'
require 'pry'

dalli = Dalli::Client.new(ENV['ISUBATA_DB_HOST'], namespace: 'isubata')
Dir.glob('/home/atton/isucon7-qualify/webapp/public/icons/*').each do |f|
  dalli.set(File.basename(f), File.read(f), 30 * 24 * 60 * 60)
end

