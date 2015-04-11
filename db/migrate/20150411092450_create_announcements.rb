class CreateAnnouncements < ActiveRecord::Migration
  def change
    create_table :announcements do |t|
      t.string :title
      t.text :contents
      t.string :author
      t.date :posted_date
      t.references :week, index: true, foreign_key: true

     # t.timestamps null: false
    end
  end
end
