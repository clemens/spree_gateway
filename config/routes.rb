Spree::Core::Engine.routes.draw do
  get  '/skrill/pay'           => 'skrill#pay',           :as => :pay_skrill
  get  '/skrill/confirm'       => 'skrill#confirm',       :as => :confirm_skrill
  post '/skrill/update_status' => 'skrill#update_status', :as => :update_skrill_status
  get  '/skrill/cancel'        => 'skrill#cancel',        :as => :cancel_skrill
end
