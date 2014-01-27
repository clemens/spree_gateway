class AddOrderIdAndPaymentMethodIdToSpreeSkrillTransactions < ActiveRecord::Base
  def change
    change_table :spree_skrill_transactions do |t|
      t.references :order
      t.text :params
    end
  end
end
