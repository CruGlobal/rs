require 'spec_helper'

describe Ride do 
  it { should belong_to :person }
  it { should belong_to :event }
  it { should have_many :rides }
  
  it '.drivers_by_event_id' do 
    Ride.stub_chain(:where, :where, :includes).and_return('result')
    Ride.drivers_by_event_id(1).should == 'result'
  end
  
  it '.riders_by_event_id' do 
    Ride.stub_chain(:where, :where, :includes).and_return('result')
    Ride.riders_by_event_id(1).should == "result"
  end
  
  it '.hidden_drivers_by_event_id' do 
    Ride.stub_chain(:where, :where, :includes).and_return('result')
    Ride.riders_by_event_id(1).should == "result"
  end
  
  it '#current_passengers_number' do 
    driver = Ride.new
    driver.drive_willingness = 3
    Ride.stub_chain(:where, :where).and_return(["1", "2"])
    driver.current_passengers_number.should == 2
  end
  
  it '#current_passengers' do 
    driver = Ride.new
    driver.drive_willingness = 3
    Ride.stub_chain(:where, :where).and_return(["1", "2"])
    driver.current_passengers.should == ["1", "2"]
  end

end
