class CreateTimeslots < ActiveRecord::Migration
  def change
    create_table :timeslots do |t|
      t.string :day
      t.string :start_time
      t.string :end_time
      # t.string :start_date
      # t.string :end_date
      t.string :venue
      t.references :subject_class

      add_foreign_key :timeslots, :subject_classes
    end
  end
end
