class AddSituationToRide < ActiveRecord::Migration
  def change
    add_column :rideshare_ride, :situation, :string
    add_column :rideshare_ride, :change, :string
    add_column :rideshare_ride, :time_hour, :string
    add_column :rideshare_ride, :time_minute, :string
    add_column :rideshare_ride, :time_am_pm, :string
    add_column :rideshare_ride, :spaces, :string
    add_column :rideshare_ride, :special_info_check, :string
    add_column :rideshare_ride, :spaces_count, :string
  end
end
