class Email < ActionMailer::Base
  default :from => 'donotreply@cru.org', :content_type => "text/html"

	def car(driver_ride_id)
		@driver = Ride.find(driver_ride_id)
		emails = []
		emails << @driver.email
		@driver.rides.each do |rider|
			emails << rider.email
		end

		@event = Event.find(@driver.event_id)

		mail(:to => emails, :subject => 'Ride information for ' + @event.event_name )
	end

end
