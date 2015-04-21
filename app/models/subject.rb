class Subject < ActiveRecord::Base
	has_many :subject_classes
	has_many :weeks
	has_many :subject_files
end
