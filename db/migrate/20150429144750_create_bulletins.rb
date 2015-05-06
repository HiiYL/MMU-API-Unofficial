class CreateBulletins < ActiveRecord::Migration
  def change
    create_table :bulletins do |t|
      t.string :title
      t.datetime :posted_on
      t.datetime :expired_on
      t.string :author
      t.string :url
      t.string :contents

      t.timestamps null: false
    end
  end
end
