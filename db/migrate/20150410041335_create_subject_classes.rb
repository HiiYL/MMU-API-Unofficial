class CreateSubjectClasses < ActiveRecord::Migration
  def change
    create_table :subject_classes do |t|
      t.string :class_number
      t.string :section
      t.string :component
      t.references :subject
    end
      add_foreign_key :subject_classes, :subjects
  end
end
