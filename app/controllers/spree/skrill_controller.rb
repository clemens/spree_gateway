module Spree
  class SkrillController < StoreController
    protect_from_forgery :except => :update_status

    def pay
      # TODO Maybe use the prepare_only option to receive a session ID from Skrill so we don't need
      # to expose the parameters?
      payment = order.payments.with_state('checkout').where(:payment_method_id => payment_method.id).first_or_create(:amount => order.total)

      options = {
        :transaction_id => payment.identifier,
        :return_url     => skrill_return_order_checkout_url(:payment_id => payment, :token => order.token),
        :cancel_url     => skrill_cancel_order_checkout_url(:token => order.token),
        :status_url     => skrill_update_status_url(:token => order.token),
      }

      redirect_to payment_method.redirect_url(order, options)
    end

    # TODO add secure return_url option as preference and use it
    def complete
      # find payment and determine its validity at the same time
      payment = order.payments.valid.find_by_id(params[:payment_id])

      if payment.present?
        SkrillTransaction.finalize_order(order)

        flash[:commerce_tracking] = 'nothing special'
        redirect_to completion_route, :notice => t(:order_processed_successfully)
      else
        render :text => 'Skrill Error. TODO'
      end
    end

    def cancel
      flash[:error] = t(:payment_has_been_cancelled)
      redirect_to edit_order_path(order)
    end

    def update_status
      SkrillTransaction.create_from_postback(params)
      head(:ok)
    end

  private

    def order
      @order ||= Order.find_by_number!(params[:order_id]).tap do |order|
        session[:access_token] ||= params[:token]
        authorize! :edit, order, session[:access_token]
      end
    end

    def payment_method
      @payment_method ||= PaymentMethod.find(params[:payment_method_id])
    end

    def completion_route
      order_path(order)
    end

  end
end
