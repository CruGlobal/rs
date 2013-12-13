class CarpoolsController < ApplicationController
  before_filter :dev_hack_session

  def index
    if session[:event_id].to_i != params[:id].to_i || params[:id].nil?
			unless params[:id].nil?
        @event = Event.where(:conference_id => params[:id]).first
			  if @event.nil?
			  	render :text => 'No registrants from your conference have registered with Rideshare yet.' and return
			  end
        render :action => :login
			else
        render :text => '' and return
		  end
    else
      @drivers = Ride.drivers_by_event_id(session[:event_local_id])
      @riders = Ride.riders_by_event_id(session[:event_local_id])
      @hidden_rides = Ride.hidden_drivers_by_event_id(session[:event_local_id])

      if @riders.size == 0 || @drivers.size == 0
        redirect_to :action => :empty
      end

      @drivers.sort! { |a,b| (!a.special_info.blank? && !b.special_info.blank?) || (a.special_info.blank? && b.special_info.blank?)?(a.person.full_name+"" <=> b.person.full_name+""):((a.special_info.blank? && !b.special_info.blank?)?(1):(-1))}
      @riders.sort! { |a,b| (!a.special_info.blank? && !b.special_info.blank?) || (a.special_info.blank? && b.special_info.blank?)?(a.person.full_name+"" <=> b.person.full_name+""):((a.special_info.blank? && !b.special_info.blank?)?(1):(-1))}

      @spaces=0
      @riders_done=0
      @drivers.each do |driver|
        @spaces += driver.number_passengers
				@riders_done+=driver.current_passengers_number
      end
      @latitude_avg=0
      @longitude_avg=0
      count=0
      @locations=Hash.new;
      @drivers.each do |driver|
        location=driver.latitude.to_s+" "+driver.longitude.to_s
        if !@locations.has_key?(location)
          @locations[location]={:latitude => driver.latitude, :longitude => driver.longitude, :rides => Array.new}
        end
        if (driver.latitude && driver.latitude != 0 && driver.longitude && driver.longitude != 0)
          @latitude_avg+=driver.latitude
          @longitude_avg+=driver.longitude
          count+=1
        end
        @locations[location][:rides].push({:type => "driver",:id => driver.id})
      end
      @riders.each do |rider|
        location=rider.latitude.to_s+" "+rider.longitude.to_s
        if !@locations.has_key?(location)
          @locations[location]={:latitude => rider.latitude, :longitude => rider.longitude, :rides => Array.new}
        end
        if (rider.latitude != 0 && rider.longitude != 0)
          @latitude_avg+=rider.latitude
          @longitude_avg+=rider.longitude
          count+=1
        end
        @locations[location][:rides].push({:type => "rider",:id => rider.id})
      end
      if count != 0
        @latitude_avg/=count
        @longitude_avg/=count
      else
        @latitude_avg=0
        @longitude_avg=0
      end
      @message =false
      @help_rides = Ride.where(:latitude => 0, :longitude => 0, :event_id => session[:event_local_id]).includes(:person)
      @message = true if @help_rides.size > 0
    end
  end

  def report
    if session[:event_id].nil?
      render :text => '' and return
    else
      @drivers = Ride.where(:drive_willingness => 1).where(:event_id => session[:event_local_id]).includes(:person)
      @unassigned_riders = Ride.where(:drive_willingness => 0).where(:driver_ride_id => 0, :event_id => session[:event_local_id]).includes(:person)
    end
  end

  def email
    if session[:event_id].nil?
      render :text => '' and return
    else
      @event = Event.find(session[:event_local_id])
    end
  end

  def email_submit
    if session[:event_id].nil?
      render :text => '' and return
    else
      @event = Event.find(session[:event_local_id])
      @drivers = Ride.where(:drive_willingness => 1).where(:event_id => session[:event_local_id]).includes(:person)

      @event.email_content = params[:content]
      @event.save!
      if params[:commit] == "Save"
        @notice = 'Email content successfully saved.'
      else
        @event.email_content = @event.email_content.gsub("\n", '<br />') if !@event.email_content.nil?
        @drivers.each do |driver|
          Email.car(driver.id).deliver
        end
        @notice = 'Emails successfully sent.'
      end
    end
    render :action => "email" and return
  end

  def get_coordinates
    @rides = Ride.where(:latitude => 0, :longitude => 0)
    @rides.each do |ride|
      address=(ride.address2 =~ /^\d/) ? ride.address2 : ride.address1
      @latitude, @longitude = Geocoder.coordinates(address+", "+ride.city+", "+ride.state+" "+ride.zip)
      ride.latitude=@latitude
      ride.longitude=@longitude
      ride.save!
    end
    redirect_to :action => :index
  end

  def update_addresses
    params[:ride].each do |ride|
      temp=Ride.find(ride[1]['id'])
      temp.update_attributes(ride[1])
      temp.save!
    end
    get_coordinates
  end

  def update_address
    ride=Ride.find(params[:rideID])
    ride.address1=params[:address1]
    ride.address2=params[:address2]
    ride.city=params[:city]
    ride.state=params[:state]
    ride.zip=params[:zip]
    address=(ride.address2 =~ /^\d/) ? ride.address2 : ride.address1
    @latitude, @longitude = Geocoder.coordinates(address+", "+ride.city+", "+ride.state+" "+ride.zip)
    ride.latitude=@latitude
    ride.longitude=@longitude
    ride.save!
    render :text => @latitude+','+@longitude
  end

  def add_rider
    begin
      rider=Ride.find(params[:rider].to_i)
      driver=Ride.find(params[:driver].to_i)
      if rider.drive_willingness == 0 && driver.drive_willingness == 1
        rider.driver_ride_id=driver.id
        rider.save!
        render :nothing => true
      else
        render :text => "failure"
      end
    rescue Exception=>e
      render :text => "failure"
    end
  end

  def remove_rider
    begin
      rider=Ride.find(params[:rider].to_i)
      rider.driver_ride_id=0;
      rider.save!
      render :nothing => true
    rescue Exception=>e
      render :text => "failure"
    end
  end
  
  def register_update
    # ride has already been created
    
    ride = Ride.find(params[:id])
    
    # TODO this and Geocoding update should be abstracted into a model instance method
    #ride.address1 = params[:address_1]
    #ride.address2 = params[:address_2]
    #ride.city     = params[:city]
    #ride.state    = params[:state]
    #ride.zip      = params[:zip]
    
    coordinates = Geocoder.coordinates(ride.address_single_line)
    @latitude  = coordinates[0]
    @longitude = coordinates[1]
    
    ride.latitude   = @latitude
    ride.longitude  = @longitude
     
    # @status, @accuracy, @status are legacy code variables possibly used in the HTML/JS. :(
    # TODO - go back and remove
    @status    = 620
    @status    = 0
    @accuracy  = 0
    
    if ride.update_attributes(ride_params)
      redirect_to(session[:redirect] || "/carpool/#{ride.event.conference_id}")
    else
      redirect_to "/carpool/register/#{ride.id}"
    end
  end

  def register
    
    # the Ride has already been created
    if params[:id].present?
      @ride=Ride.find(params[:id])
      if session[:event_id] != @ride.event.conference_id
        render :text => "" and return
      end
      person = @ride.person
      @event = @ride.event
      params[:redirect]="/"+@ride.event.conference_id.to_s
      session[:redirect]=params[:redirect]
      session[:event]=@event.id
      session[:personID]=person.personID
    
    # the Ride has not been created
    else
      session[:personID] ||= params[:person_id]
      session[:country]  ||= params[:country]
      session[:phone]    ||= params[:phone]
      session[:email]    ||= params[:email]
      session[:gender]   ||= params[:gender]
      session[:school_year] ||= params[:school_year]
      session[:redirect] ||= params[:redirect]
      session[:first_name] ||= params[:first_name]
      session[:last_name] ||= params[:last_name]
      session[:contact_method] ||= params[:contact_method]
      
      person = Person.where(:personID => params[:person_id] || session[:personID]).first
      
      @event = Event.where(:conference_id => params[:conference_id]).first
      if @event.nil?
        @event = Event.new({:email_content=>'',:event_name => params[:conference_name], :conference_id => params[:conference_id].to_i, :password => ""}, without_protection: true)
        @event.save!
      end
      session[:event]=@event.id
      
      @ride = Ride.new(:driver_ride_id => 0,
        :event_id => @event.id, 
        :person_id => person.personID, 
        :address1 => params[:address_1], 
        :address2 => params[:address_2], 
        :address3 => '', 
        :address4 => '', 
        :country => '', 
        :city => params[:city], 
        :state => params[:state], 
        :zip => params[:zip], 
        :phone => session[:phone], 
        :contact_method => params[:contact], 
        :number_passengers => ((params[:spaces].blank?) ? 0 : params[:spaces]), :drive_willingness => (params[:situation] == "ride") ? 0 : (params[:situation] == "drive") ? (params[:ride] == 'yes') ? 3 : 1 : 2,
        :situation => params[:situation],
        :change => params[:change],
        :time_hour => params[:time_hour],
        :time_minute => params[:time_minute],
        :time_am_pm => params[:time_am_pm],
        :spaces => params[:spaces],
        :depart_time => params[:time], 
        :special_info => params[:special_info], 
        :email => session[:email])
      
      begin
        coordinates = Geocoder.coordinates(@ride.address_single_line)
        @ride.latitude = coordinates[0]
        @ride.longitude = coordinates[1]
      rescue
        # ignore coordinate failures
      end

      #if request.post?
        @ride.save!
      #  redirect_to session[:redirect]
      #  return
      #end
    end
    if !person.nil?
      if person.first_name == params[:first_name] && person.last_name == params[:last_name] && (person.yearInSchool == params[:school_year]||(person.yearInSchool.nil?&&(params[:school_year]=="null"||params[:school_year]=="")) )
        @ride = Ride.where(:person_id => person.personID, :event_id => @event.id).first
      end
      if !@ride.nil?
        params[:situation]=(@ride.drive_willingness == 0)? 'ride':(@ride.drive_willingness == 1 || @ride.drive_willingness == 3) ? 'drive' : 'done'
        #params[:time]=(ride.drive_willingness == 2) ? nil:ride.departureTime
        params[:time]=@ride.departureTime
        if !params[:time].nil?
          params[:time_hour] = params[:time][0,2].to_i
          params[:time_minute] = params[:time][3,5].to_i
          if (params[:time_hour] < 12)
            params[:time_am_pm] = "AM"
          else
            params[:time_am_pm] = "PM"
            params[:time_hour] = params[:time_hour]-12
          end
        else
          params[:time_hour] = 12
          params[:time_minute] = 0
          params[:time_am_pm] = "PM"
        end
        params[:spaces]=@ride.number_passengers
        params[:address_1]=@ride.address1
        params[:address_2]=@ride.address2
        params[:city]=@ride.city
        params[:state]=@ride.state
        params[:zip]=@ride.zip
        params[:special_info]=@ride.special_info
        params[:contact_method]=@ride.contact_method
        params[:ride]=(@ride.drive_willingness == 3) ? 'yes':'no'
        @done="You have already finished this registration. You can update your information here or <a href='"+session[:redirect]+"'>Go Back</a>"
      end
    end
  end

  def login
    @event = Event.where(:conference_id => params[:id]).first
    if @event.nil?
      render :text => 'No registrants from your conference have registered with Rideshare yet.'
      return
    end
    if params[:key] # && Digest::MD5.hexdigest(params[:key]) == @event.password
      # if request.env['REQUEST_METHOD'] == 'GET' && request.env['HTTP_REFERER'] && (request.env['HTTP_REFERER'].include?('conferenceregistrationtool.com') || request.env['HTTP_REFERER'].include?('crs.int.uscm.org'))
        session[:event_id] = @event.conference_id
        session[:event_local_id] = @event.id
        redirect_to :action => :index, :id => @event.conference_id
      # end
    end
  end

  def empty
  end


  private

  def dev_hack_session
    if Rails.env.development?

      # event_id is the rideshare_event.conference_id
      session[:event_id] = params[:event_id].to_i if params[:event_id]

      # event_local_id is the rideshare_event.event_id
      session[:event_local_id] = params[:event_local_id].to_i if params[:event_local_id]
    end
  end

  def ride_params
    params[:ride]
  end
end
