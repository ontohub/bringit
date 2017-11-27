require 'bringit'
require 'memory_benchmark'

memory_benchmark do
  repo = Bringit::Repository.new(ARGV.first)
  repo.search_files('baz', '5a90ed56c6270627fe92def4eeca1ef150fc2d4c')
end
