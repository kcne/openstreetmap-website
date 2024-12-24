class AddDescriptionToNotes < ActiveRecord::Migration[7.2]
  def change
    add_column :notes, :description, :text, :null => false, :default => ""
    add_column :notes, :user_id, :bigint
    add_column :notes, :user_ip, :inet
  end
end
