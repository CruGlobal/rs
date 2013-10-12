Rs::Application.routes.draw do
  
  get 'carpool/login/:id'         => 'carpools#login', via: [:get, :post]
  get 'carpool/email'             => 'carpools#email'
  post 'carpool/email'            => 'carpools#email_submit'
  get 'carpool/get_coordinates'   => 'carpools#get_coordinates'
  get 'carpool/report'            => 'carpools#report'
  get 'carpool/register/:id'      => 'carpools#register'
  post 'carpool/register'         => 'carpools#register', as: 'register_submit'
  get 'carpool/update_addresses'  => 'carpools#update_addresses', via: [:get, :update]
  get 'carpool/:id/empty'         => 'carpools#empty'
  get 'carpool/:id'               => 'carpools#index'
  get 'carpool'                   => 'carpools#index'
  
  root :to => 'carpools#index'

end

