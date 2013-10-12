# == Schema Information
# Schema version: 17
#
# Table name: ministry_newaddress
#
#  AddressID            :integer(10)   not null, primary key
#  deprecated_startDate :string(25)    
#  deprecated_endDate   :string(25)    
#  address1             :string(55)    
#  address2             :string(55)    
#  address3             :string(55)    
#  address4             :string(55)    
#  city                 :string(50)    
#  state                :string(50)    
#  zip                  :string(10)    
#  country              :string(64)    
#  homePhone            :string(25)    
#  workPhone            :string(25)    
#  cellPhone            :string(25)    
#  fax                  :string(25)    
#  email                :string(200)   
#  url                  :string(100)   
#  contactName          :string(50)    
#  contactRelationship  :string(50)    
#  addressType          :string(20)    
#  dateCreated          :datetime      
#  dateChanged          :datetime      
#  createdBy            :string(50)    
#  changedBy            :string(50)    
#  fk_PersonID          :integer(10)   
#  email2               :string(200)   
#  start_date           :datetime      
#  end_date             :datetime      
#

class Address < ActiveRecord::Base
  self.table_name   = "ministry_newaddress"
  self.primary_key  = "addressID"
  
  belongs_to :person, 
    :foreign_key => "fk_PersonID"
  
  before_save :stamp
  
  #set dateChanged and changedBy
  def stamp
    self.dateChanged = Time.now
    self.changedBy = ApplicationController.application_name
  end
  
  def display_html
    ret_val = address1 || ''
    ret_val += '<br/>'+address2 unless address2.nil? || address2.empty? 
    ret_val += '<br/>' unless ret_val.empty?
    ret_val += city+', ' unless city.nil? || city.empty? 
    ret_val += state + ' ' unless state.nil?
    ret_val += zip unless zip.nil?
    ret_val += '<br/>'+country+',' unless country.nil? || country.empty? || country == 'USA'
    return ret_val
  end
  
  def phone_number
    phone = (self.homePhone && !self.homePhone.empty?) ? self.homePhone : self.cellPhone
    phone = (phone && !phone.empty?) ? phone : self.workPhone
    phone
  end
end
