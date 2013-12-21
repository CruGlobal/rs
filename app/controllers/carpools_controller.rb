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
      @drivers = Ride.where(:drive_willingness => 1, :event_id => session[:event_local_id]).includes(:person)
      @unassigned_riders = Ride.where(:drive_willingness => 0, :driver_ride_id => 0, :event_id => session[:event_local_id]).includes(:person)
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
        flash[:notice] = 'Emails successfully sent.'
      end
    end
    redirect_to("/carpool/#{session[:event_id]}")
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
      rider=Ride.find(params[:rider])
      driver=Ride.find(params[:driver])
      if rider.drive_willingness == 0 && driver.drive_willingness == 1
        rider.driver_ride_id=driver.id
        rider.save!
        render :text => ''
      else
        render :text => "failure"
      end
    rescue Exception=>e
      raise e
      render :text => "failure"
    end
  end

  def remove_rider
    begin
      rider=Ride.find(params[:rider].to_i)
      rider.driver_ride_id = 0
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

    # @status, @accuracy, @status are legacy code variables possibly used in the HTML/JS. :(
    # TODO - go back and remove
    @status    = 620
    @status    = 0
    @accuracy  = 0

    if ride.update_attributes(ride_params)
      redirect_to(session[:redirect] || "/carpool/#{ride.event.conference_id}")
    else
      flash[:alert] = 'Please let us know if you can drive or need a ride'
      redirect_to "/carpool/register/#{ride.id}"
    end
  end

  def register

    # the Ride has already been created
    if params[:id].present?
      @ride=Ride.find(params[:id])
      #if session[:event_id] != @ride.event.conference_id
      #  render :text => "" and return
      #end
      person = @ride.person
      @event = @ride.event
      session[:redirect] = params[:redirect] || "/carpool/"+@ride.event.conference_id.to_s
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
      session[:redirect] = params[:redirect] if params[:redirect]
      session[:first_name] ||= params[:first_name]
      session[:last_name] ||= params[:last_name]
      session[:contact_method] ||= params[:contact_method]

      person = Person.where(:personID => params[:person_id] || session[:personID]).first

      @event = Event.where(:conference_id => params[:conference_id]).first
      if @event.nil?
        @event = Event.new({:email_content=>'',:event_name => params[:conference_name], :conference_id => params[:conference_id].to_i, :password => ""}, without_protection: true)
        @event.save!
      end
      session[:event] = @event.id

      unless @ride = Ride.where(person_id: person.id, event_id: @event.id).first
        @ride = Ride.new(:event_id => @event.id,
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
                          :contact_method => params[:contact] || 'email',
                          :number_passengers => params[:spaces] || 3,
                          :situation => params[:situation],
                          :change => params[:change],
                          :time_hour => params[:time_hour],
                          :time_minute => params[:time_minute],
                          :time_am_pm => params[:time_am_pm],
                          :spaces => params[:spaces] || 3,
                          :depart_time => params[:time],
                          :special_info => params[:special_info] || 'no',
                          :email => session[:email],
                          :situation => 'done',
                          :change => 'yes',
                          :special_info_check => 'no'
        )

        begin
          coordinates = Geocoder.coordinates(@ride.address_single_line)
          @ride.latitude = coordinates[0]
          @ride.longitude = coordinates[1]
        rescue
          # ignore coordinate failures
        end

        @ride.save!
      end
    end

    if @ride.situation.present?
      @done="You have already finished this registration. You can update your information here or <a href='"+session[:redirect]+"'>Go Back</a>"
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
