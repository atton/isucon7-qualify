require './app'

system('rm tmp/stackprof/*')
use StackProf::Middleware, enabled: true, mode: :wall, raw: true, interval: 100, save_every: 1, path: 'tmp/stackprof/'

run App
