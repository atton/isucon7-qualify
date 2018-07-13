require 'dalli'
require 'pry'

dalli = Dalli::Client.new
Dir.glob('/home/atton/isucon7-qualify/webapp/public/icons/*').each do |f|
  dalli.set(File.basename(f), File.read(f), nil, raw: true)
end

