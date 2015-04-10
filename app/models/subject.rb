class Subject < ActiveRecord::Base
	belongs_to :timetable
	has_many :subject_classes
end
