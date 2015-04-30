class BulletinWorker
  include Sidekiq::Worker

  def perform(project_id)
    Bulletin.update_bulletin
  end
end
