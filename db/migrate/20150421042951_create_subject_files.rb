class CreateSubjectFiles < ActiveRecord::Migration
  def change
    create_table :subject_files do |t|
      t.string :file_name
      t.string :token
      t.string :content_id
      t.string :content_type
      t.string :file_path
      t.references :subject, index: true, foreign_key: true

      # t.timestamps null: false
    end
  end
end
