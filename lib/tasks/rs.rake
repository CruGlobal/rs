namespace :rs do

  desc 'update all Ride lat/longs for an event'
  #
  #  example usuage, rake "rs:update_event_lat_long[20]"
  #
  task :update_event_lat_long => :environment do |task, args|
    Ride.where(latitude: nil).find_each do |ride|
      coordinates = Geocoder.coordinates(ride.address_single_line)
      if coordinates
        ride.latitude  = coordinates[0]
        ride.longitude = coordinates[1]
        ride.save
      else
        puts "No coordinates for: #{ride.address_single_line}"
      end
    end
  end

end
