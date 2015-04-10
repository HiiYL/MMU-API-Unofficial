class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.string :status
      t.string :name
      t.references :timetable

      add_foreign_key :subjects, :timetables
    end
  end
end
