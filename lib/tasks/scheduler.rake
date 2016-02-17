desc "This task is called by the Heroku scheduler add-on"
task :update_bulletin => :environment do
  puts "Updating bulletin..."
  Bulletin.update_bulletin
  puts "done."
end