require 'digest/md5'

module Spree
  class SkrillTransaction < ActiveRecord::Base
    PAYMENT_STATUSES = {
      :processed  =>  2,
      :pending    =>  0,
      :cancelled  => -1,
      :failed     => -2,
      :chargeback => -3,
    }

    class InvalidTransactionError < StandardError; end

    belongs_to :order, :class_name => 'Spree::Order'

    serialize :params

    def self.create_from_postback(params)
      transaction = create!(
        :order_id       => params[:order_id],
        :email          => params[:pay_from_email],
        :amount         => params[:mb_amount],
        :currency       => params[:mb_currency],
        :transaction_id => params[:mb_transaction_id],
        :customer_id    => params[:customer_id],
        :payment_type   => params[:payment_type],
        :params         => params
      )

      transaction.process
    end

    def self.finalize_order(order)
      # really? - at least that's similar to other extensions seem to be doing it
      unless order.state == 'complete'
        order.state = 'complete'
        # manually finalize it because that's what happens after the transition to complete in the state machine
        order.finalize!
      end
    end

    # Note: We might want to do something less harsh than raise an exception if the transaction
    # isn't legit or has failed.
    def process
      payment.source = self
      payment.save!

      raise InvalidTransactionError.new("Transaction failed (not legit): #{params.inspect}") unless legit?

      if pending?
        payment.pend! unless payment.pending?
      elsif completed?
        payment.complete! unless payment.completed?
      else
        # FIXME Maybe use payment.failure! (at least for actual failures)
        raise InvalidTransactionError.new("Transaction failed (not pending/completed): #{params.inspect}")
      end

      self.class.finalize_order(order)
    end

  private

    def legit?
      correct_receiver? && valid_signature?
    end

    def correct_receiver?
      payment_method.preferred_merchant_id == params[:merchant_id]
    end

    def valid_signature?
      parts = [payment_method.preferred_merchant_id, payment.identifier, Digest::MD5.digest(payment_method.preferred_secret_word).upcase, order.total, order.currency, params[:status]]
      Digest::MD5.digest(parts.join('')).upcase == params[:md5sig]
    end

    def pending?
      params[:status] == PAYMENT_STATUSES[:pending]
    end

    def completed?
      params[:status] == PAYMENT_STATUSES[:processed]
    end

    def payment
      @payment ||= order.payments.find_by_identifier!(params[:transaction_id])
    end

    def payment_method
      @payment_method ||= payment.payment_method
    end

  end
end
