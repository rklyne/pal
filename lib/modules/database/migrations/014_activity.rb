Sequel.migration do
  up do
    create_table(:activities) do
      primary_key :id
      String :name, null: false
      String :description
      Integer :role_id
      Integer :server_id, null: false
      Integer :channel_id, null: false
      Integer :message_id
    end

    create_table(:participants) do
      primary_key :id
      Integer :discord_id, null: false
      foreign_key :activity_id, :activities, null: false, on_delete: :cascade
    end
  end

  down do
    create_table(:activities)
    create_table(:participants)
  end
end
