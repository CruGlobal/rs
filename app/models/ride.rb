class Ride < ActiveRecord::Base
	self.table_name = "rideshare_ride"
	self.primary_key = "id"
	
	belongs_to :person
	belongs_to :event
	has_many :rides, :foreign_key => "driver_ride_id"
	
	def self.drivers_by_event_id(event_id)
		result = Ride.where('rideshare_ride.drive_willingness in (1, 2, 3)').
			where('rideshare_ride.event_id' => event_id).
			includes(:person)
		result
	end
	
	def self.riders_by_event_id(event_id)
		result = where(:drive_willingness => 0).
      where(:event_id => event_id).
       includes(:person)
    result
	end
	
	def self.hidden_drivers_by_event_id(event_id)
		result = where(:drive_willingness => 2).
      where(:event_id => event_id).
      includes(:person)
    result
	end
	
	def current_passengers_number
		return nil unless drive_willingness.between?(1, 3)
		current_passengers.length
	end
	
	def current_passengers
		return nil unless drive_willingness.between?(1, 3)
		self.class.where(:driver_ride_id => id).where("id != driver_ride_id")
	end
	
	def address
		returnval=address1
		returnval+="<br />"+address2 unless address2.empty?
		returnval+="<br />"+city+", "+state+" "+zip
	end
	
	def departureTime
		if (depart_time.nil?)
			"24:00"
		else
			if (depart_time.min < 10)
			  if (depart_time.hour < 10)
			    "0"+depart_time.hour.to_s+":0"+depart_time.min.to_s
			  else
			    depart_time.hour.to_s+":0"+depart_time.min.to_s
		    end
			else
			  if (depart_time.hour < 10)
			    "0"+depart_time.hour.to_s+":"+depart_time.min.to_s
	      else
				  depart_time.hour.to_s+":"+depart_time.min.to_s
			  end
			end
		end
	end
	
	def departureTimeNice
		if (depart_time.nil?)
			"12:00 AM"
		else
			if (depart_time.hour > 12)
				if (depart_time.min < 10)
					(depart_time.hour-12).to_s+":0"+depart_time.min.to_s+" PM"
				else
					(depart_time.hour-12).to_s+":"+depart_time.min.to_s+" PM"
				end
			else
				if (depart_time.min < 10)
				  # adding "0" to string for string substring operations, IE 01:15 AM
					depart_time.hour.to_s+":0"+depart_time.min.to_s+" AM"
				else
					depart_time.hour.to_s+":"+depart_time.min.to_s+" AM"
				end
			end
		end
	end
end
