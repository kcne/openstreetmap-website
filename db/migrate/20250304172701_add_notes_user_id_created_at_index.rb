class AddNotesUserIdCreatedAtIndex < ActiveRecord::Migration[7.1]
  disable_ddl_transaction!

  def change
    add_index :notes, [:user_id, :created_at], algorithm: :concurrently
  end
end 