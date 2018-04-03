Sequel.migration do
  up do
    create_table(:relays) do
      primary_key :id
      String :name, null: false, unique: true
      String :key, null: false
    end

    create_table(:relay_targets) do
      primary_key :id
      foreign_key :relay_id, :relays, null: false, on_delete: :cascade
      Integer :channel_id, null: false
    end
  end

  down do
    drop_table(:relays)
    drop_table(:relay_targets)
  end
end
