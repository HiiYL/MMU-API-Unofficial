class CreateSubjects < ActiveRecord::Migration
  def change
    create_table :subjects do |t|
      t.string :status
      t.string :name
    end
  end
end
