## rs = Ridesahre
Ridesahre is a Ruby on Rails app to coordinate mass carpooling.

### Development Environment
Rideshare is a session based application that inherits session variables from 
CRS. To work on the rails app apart from CRS defining the session for you, 
define desired session parameters via HTTP params. For example, 
    
    git clone git@github.com:thelabtech/rs.git
    
    # setup 
    ## database.yml
    ## google.rb
    ## password.rb
    #
    # See -> Environment Variables
    
    cd rs
    
    rails server # defaults to "development" env
    
Go to [http://localhost:3000/carpool/1045?event_id=1045&event_local_id=20]
(http://localhost:3000/carpool/1045?event_id=1045&event_local_id=20).
    
The controller sets the session params according to defined HTTP params. The 
code that does this is here, 

### Environment Variables
The Ridesare app expects 2 constants to be defined:

`RIDESHARE_PASSWORD`: defined in "app/config/initializers/password.rb". See 
password.rb.example for details.

`GOOGLE_MAPS2_KEY`: defined in "app/config/initializers/google.rb". See 
google.rb.example for details.

### Testing

### Production 
