class Week < ActiveRecord::Base
  belongs_to :subject
  has_many :announcements
end
