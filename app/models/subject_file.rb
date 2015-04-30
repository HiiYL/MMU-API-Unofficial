class SubjectFile < ActiveRecord::Base
	belongs_to :subject
	belongs_to :announcement
end
