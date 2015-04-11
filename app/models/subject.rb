class Subject < ActiveRecord::Base
	belongs_to :timetable
	has_many :subject_classes
	has_many :weeks
end
