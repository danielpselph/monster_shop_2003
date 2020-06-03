require 'rails_helper'

RSpec.describe "As a visitor" do
  describe "When I visit a merchant show page" do
    it "I can delete a merchant" do
      bike_shop = Merchant.create(name: "Brian's Bike Shop", address: '123 Bike Rd.', city: 'Richmond', state: 'VA', zip: 80203)

      visit "merchants/#{bike_shop.id}"

      click_on "Delete Merchant"

      expect(current_path).to eq('/merchants')
      expect(page).to_not have_content("Brian's Bike Shop")
    end

    it "I can delete a merchant that has items" do
      bike_shop = Merchant.create(name: "Brian's Bike Shop", address: '123 Bike Rd.', city: 'Denver', state: 'CO', zip: 80203)
      chain = bike_shop.items.create(name: "Chain", description: "It'll never break!", price: 50, image: "https://www.rei.com/media/b61d1379-ec0e-4760-9247-57ef971af0ad?size=784x588", inventory: 5)

      visit "merchants/#{bike_shop.id}"

      click_on "Delete Merchant"

      expect(current_path).to eq('/merchants')
      expect(page).to_not have_content("Brian's Bike Shop")
    end

    it "I can't delete a merchant that has orders" do
      user = create(:default_user)
      mike = Merchant.create(name: "Mike's Print Shop", address: '123 Paper Rd.', city: 'Denver', state: 'CO', zip: 80203)
      meg = Merchant.create(name: "Meg's Bike Shop", address: '123 Bike Rd.', city: 'Denver', state: 'CO', zip: 80203)
      brian = Merchant.create(name: "Brian's Dog Shop", address: '123 Dog Rd.', city: 'Denver', state: 'CO', zip: 80204)

      tire = meg.items.create(name: "Gatorskins", description: "They'll never pop!", price: 100, image: "https://www.rei.com/media/4e1f5b05-27ef-4267-bb9a-14e35935f218?size=784x588", inventory: 12)
      paper = mike.items.create(name: "Lined Paper", description: "Great for writing on!", price: 20, image: "https://cdn.vertex42.com/WordTemplates/images/printable-lined-paper-wide-ruled.png", inventory: 3)
      pencil = mike.items.create(name: "Yellow Pencil", description: "You can write on paper with it!", price: 2, image: "https://images-na.ssl-images-amazon.com/images/I/31BlVr01izL._SX425_.jpg", inventory: 100)
      pulltoy = brian.items.create(name: "Pulltoy", description: "It'll never fall apart!", price: 14, image: "https://www.valupets.com/media/catalog/product/cache/1/image/650x/040ec09b1e35df139433887a97daa66f/l/a/large_rubber_dog_pull_toy.jpg", inventory: 7)

      visit "/"
      click_link "Log In"

      fill_in :email,	with: "#{user.email}"
      fill_in :password,	with: "#{user.password}"

      click_button "Login"

      visit "/items/#{paper.id}"
      click_on "Add To Cart"
      visit "/items/#{paper.id}"
      click_on "Add To Cart"
      visit "/items/#{tire.id}"
      click_on "Add To Cart"
      visit "/items/#{pencil.id}"
      click_on "Add To Cart"

      visit "/cart"
      click_on "Checkout"

      name = "Bert"
      address = "123 Sesame St."
      city = "NYC"
      state = "New York"
      zip = 10001

      fill_in :name, with: name
      fill_in :address, with: address
      fill_in :city, with: city
      fill_in :state, with: state
      fill_in :zip, with: zip

      click_button "Create Order"

      visit "/merchants/#{meg.id}"
      expect(page).to_not have_link("Delete Merchant")

      # visit "/merchants/#{brian.id}"
      # expect(page).to have_link("Delete Merchant")
    end
  end
end

RSpec.describe "As an admin" do
  describe "when I visit the index page" do
    before :each do
      @mike = Merchant.create(name: "Mike's Print Shop", address: '123 Paper Rd.', city: 'Denver', state: 'CO', zip: 80203)
      @meg = Merchant.create(name: "Meg's Bike Shop", address: '123 Bike Rd.', city: 'Denver', state: 'CO', zip: 80203)

      @tire = @meg.items.create(name: "Gatorskins", description: "They'll never pop!", price: 100, image: "https://www.rei.com/media/4e1f5b05-27ef-4267-bb9a-14e35935f218?size=784x588", inventory: 12)
      @paper = @mike.items.create(name: "Lined Paper", description: "Great for writing on!", price: 20, image: "https://cdn.vertex42.com/WordTemplates/images/printable-lined-paper-wide-ruled.png", inventory: 3)
      @pencil = @mike.items.create(name: "Yellow Pencil", description: "You can write on paper with it!", price: 2, image: "https://images-na.ssl-images-amazon.com/images/I/31BlVr01izL._SX425_.jpg", inventory: 100)

      admin = create(:admin)
      visit "/"
      click_link "Log In"

      fill_in :email,	with: "#{admin.email}"
      fill_in :password,	with: "#{admin.password}"

      click_button "Login"
    end

    it "can disable a merchant and all their items" do
      visit admin_merchants_path

      within ".merchant-#{@meg.id}" do
        expect(page).to have_button "Disable"
      end
      within ".merchant-#{@mike.id}" do
        click_button "Disable"
      end

      expect(current_path).to eq(admin_merchants_path)
      expect(page).to have_content("#{@mike.name} is now disabled")
      within ".merchant-#{@mike.id}" do
        expect(page).to have_button "Enable"
        expect(page).to_not have_button "Disable"
      end
      within ".merchant-#{@meg.id}" do
        expect(page).to have_button "Disable"
      end

      expect(Merchant.find(@mike.id).active?).to eq(false)
      expect(Item.find(@paper.id).active?).to eq(false)
      expect(Item.find(@pencil.id).active?).to eq(false)
    end

    it "can re-enable a disabled merchant and all their items" do
      @mike.update_attribute(:active?, false)
      @paper.update_attribute(:active?, false)
      @pencil.update_attribute(:active?, false)
      visit admin_merchants_path

      within ".merchant-#{@mike.id}" do
        click_button "Enable"
      end

      expect(current_path).to eq(admin_merchants_path)
      expect(page).to have_content("#{@mike.name} is now enabled")
      within ".merchant-#{@mike.id}" do
        expect(page).to have_button "Disable"
        expect(page).to_not have_button "Enable"
      end
      within ".merchant-#{@meg.id}" do
        expect(page).to have_button "Disable"
      end

      expect(Merchant.find(@mike.id).active?).to eq(true)
      expect(Item.find(@paper.id).active?).to eq(true)
      expect(Item.find(@pencil.id).active?).to eq(true)
    end
  end
end

# As an admin
# When I visit the admin's merchant index page ('/admin/merchants')
# I see a "disable" button next to any merchants who are not yet disabled
# When I click on the "disable" button
# I am returned to the admin's merchant index page where I see that the merchant's account is now disabled
# And I see a flash message that the merchant's account is now disabled
#
# As an admin
# When I visit the merchant index page
# And I click on the "disable" button for an enabled merchant
# Then all of that merchant's items should be deactivated
#
# As an admin
# When I visit the merchant index page
# I see an "enable" button next to any merchants whose accounts are disabled
# When I click on the "enable" button
# I am returned to the admin's merchant index page where I see that the merchant's account is now enabled
# And I see a flash message that the merchant's account is now enabled
#
# As an admin
# When I visit the merchant index page
# And I click on the "enable" button for a disabled merchant
# Then all of that merchant's items should be activated
