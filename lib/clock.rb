require File.expand_path('../../config/boot',        __FILE__)
require File.expand_path('../../config/environment', __FILE__)
require 'clockwork'

include Clockwork

every(1.day, 'Run my worker daily', at: '04:30', tz: 'UTC') { Sidekiq::Client.enqueue(MyWorker) }
every(7.day, 'Send weekly reports', at: '02:00', tz: 'UTC') { Sidekiq::Client.enqueue(ReportWorker) }