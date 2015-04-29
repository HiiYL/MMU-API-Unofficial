class CreateBulletins < ActiveRecord::Migration
  def change
    create_table :bulletins do |t|
      t.string :title
      t.string :posted_date
      t.string :expired_date
      t.string :author
      t.string :url
      t.string :contents

      t.timestamps null: false
    end
  end
end
