require 'clockwork'

include Clockwork

every(1.minute, Bulletin.update_bulletin) { Sidekiq::Client.enqueue(MyWorker) }