namespace :rs do

  desc 'update all Ride lat/longs for an event'
  #
  #  example usuage, rake "rs:update_event_lat_long[20]"
  #
  task :update_event_lat_long => :environment do |task, args|
    Ride.find_each do |ride|
      coordinates = Geocoder.coordinates(ride.address_single_line)
      ride.latitude  = coordinates[0]
      ride.longitude = coordinates[1]
      ride.save
    end
  end

end
