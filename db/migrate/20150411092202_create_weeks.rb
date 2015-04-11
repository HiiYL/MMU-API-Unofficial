class CreateWeeks < ActiveRecord::Migration
  def change
    create_table :weeks do |t|
      t.references :subject, index: true, foreign_key: true
      t.string :title

     # t.timestamps null: false
    end
  end
end
