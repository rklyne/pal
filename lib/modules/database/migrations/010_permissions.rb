Sequel.migration do
  up do
    create_table(:permissions) do
      primary_key :id
      Integer :snowflake, unique: true, null: false
      String :type, null: false
      Integer :level, null: false, default: 0
    end
  end

  down do
    drop_table(:permissions)
  end
end
