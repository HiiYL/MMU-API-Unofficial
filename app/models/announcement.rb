class Announcement < ActiveRecord::Base
  belongs_to :week
  has_many :subject_files
end
