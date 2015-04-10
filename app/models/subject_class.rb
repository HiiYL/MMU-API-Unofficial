class SubjectClass < ActiveRecord::Base
	belongs_to :subject
	has_many :timeslots
end
