module Spree
  class BillingIntegration::Skrill::QuickCheckout < BillingIntegration
    preference :merchant_id,     :string
    preference :secret_word,     :string
    preference :language,        :string, :default => 'EN' # TODO use something based on I18n.locale?
    preference :payment_options, :string, :default => 'ACC' # ACC = all card types; see Merchant Integration Manual for acceptable codes

    attr_accessible :preferred_merchant_id, :preferred_secret_word,
                    :preferred_language, :preferred_payment_options

    def provider_class
      ActiveMerchant::Billing::Skrill
    end

    # We use reverse_merge so all options can be changed by passing them in as parameters.
    def redirect_url(order, options = {})
      # preferences
      options.reverse_merge!(
        :merchant_id     => preferred_merchant_id,
        :language        => preferred_language,
        :payment_methods => preferred_payment_options
      )

      # order basics
      options.reverse_merge!(
        :order_id => order.number,
        :amount   => order.total,
        :currency => order.currency
      )

      # order details
      options.reverse_merge!(
        :pay_from_email        => order.email,
        :firstname             => order.bill_address.firstname,
        :lastname              => order.bill_address.lastname,
        :address               => order.bill_address.address1,
        :address2              => order.bill_address.address2,
        :phone_number          => order.bill_address.phone.gsub(/\D/,'') if order.bill_address.phone.present?, # only numeric values are accepted!
        :city                  => order.bill_address.city,
        :postal_code           => order.bill_address.zipcode,
        :state                 => order.bill_address.state.try(:abbr) || order.bill_address.state_name.to_s,
        :country               => order.bill_address.country.name
      )

      # visual stuff
      options.reverse_merge!(
        :recipient_description => Spree::Config[:site_name],
        :detail1_text          => order.number,
        :detail1_description   => 'Order:', # TODO i18n
        :hide_login            => 1 # really? maybe set via preference?
      )

      # other
      options.reverse_merge!(
        :merchant_fields       => 'platform,order_id,payment_method_id',
        :platform              => 'Spree'
      )

      provider.payment_url(options)
    end

  end
end
