class AddPhoneAndMessages < ActiveRecord::Migration
  def change
    create_table :phones do |t|
      t.string :phone_number
      t.string :phone_carrier
    end

    create_table :messages do |t|
      t.string  :content
      t.integer :phone_id
    end
  end
end
