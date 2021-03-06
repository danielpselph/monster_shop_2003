require 'rails_helper'

describe 'User profile edit page',type: :feature do
  before :each do
    @user = create(:default_user)
    @user_new = create(:default_user)

    visit "/"
    click_link "Log In"
    fill_in :email,	with: "#{@user.email}"
    fill_in :password, with: "#{@user.password}"
    click_button "Login"
  end

  it "edit a user profile" do
    click_button "Edit Profile"
    expect(current_path).to eq "/users/edit"
    expect(find_field(:name).value).to eq(@user.name)
    expect(find_field(:address).value).to eq(@user.address)
    expect(find_field(:state).value).to eq(@user.state)
    expect(find_field(:city).value).to eq(@user.city)
    expect(find_field(:zip).value).to eq(@user.zip)
    expect(find_field(:email).value).to eq(@user.email)

    User.destroy(@user_new.id)
    fill_in :name,	with: @user_new.name
    fill_in :address,	with: @user_new.address
    fill_in :city,	with: @user_new.city
    fill_in :state,	with: @user_new.state
    fill_in :zip,	with: "34567"
    fill_in :email,	with: @user_new.email
    fill_in :password, with: @user.password
    fill_in :password_confirmation, with: @user.password
    click_button "Submit"

    expect(current_path).to eq(profile_path)
    expect(page).to have_content("User profile updated!")
    expect(page).to have_content(@user_new.name)
    expect(page).to have_content(@user_new.address)
    expect(page).to have_content(@user_new.state)
    expect(page).to have_content(@user_new.city)
    expect(page).to have_content("34567")
    expect(page).to have_content(@user_new.email)
  end

  it "does not update without correct password" do
    click_button "Edit Profile"
    fill_in :name,	with: @user_new.name
    click_button "Submit"

    expect(current_path).to eq "/users/edit"
    expect(page).to have_content("Incorrect password or confirmation")
    expect(User.find(@user.id).name).to eq(@user.name)

    fill_in :name,	with: @user_new.name
    fill_in :password, with: @user.password
    fill_in :password_confirmation, with: "notthepassword"

    expect(current_path).to eq "/users/edit"
    expect(page).to have_content("Incorrect password or confirmation")
    expect(User.find(@user.id).name).to eq(@user.name)
  end

  it "does not update if not enough information is supplied" do
    click_button "Edit Profile"
    fill_in :name,	with: ""
    fill_in :password, with: @user.password
    fill_in :password_confirmation, with: @user.password
    click_button "Submit"

    expect(current_path).to eq "/users/edit"
    expect(page).to have_content("Name can't be blank")
    expect(User.find(@user.id).name).to eq(@user.name)
  end

  it "can update a password for the user" do
    click_button "Edit Password"
    expect(current_path).to eq "/users/password/edit"
    fill_in :password, with: "newpassword"
    fill_in :password_confirmation, with: "newpassword"
    click_button "Submit"

    expect(current_path).to eq(profile_path)
    expect(page).to have_content("Password updated!")
    new_pw_user = User.find(@user.id)
    pw_test = (BCrypt::Password.new(new_pw_user.password_digest) == "newpassword")
    expect(pw_test).to eq(true)
  end

  it "does not update the password if not correctly confirmed" do
    click_button "Edit Password"
    fill_in :password, with: "newpassword"
    fill_in :password_confirmation, with: "notnewpassword"
    click_button "Submit"

    expect(current_path).to eq("/users/password/edit")
    expect(page).to have_content("Password confirmation field did not match")
    new_pw_user = User.find(@user.id)
    pw_test = (BCrypt::Password.new(new_pw_user.password_digest) == @user.password)
    expect(pw_test).to eq(true)
  end

  it "does not allow a user to use an email used by another user" do
    click_button "Edit Profile"
    fill_in :email,	with: @user_new.email
    fill_in :password, with: @user.password
    fill_in :password_confirmation, with: @user.password
    click_button "Submit"

    expect(current_path).to eq "/users/edit"
    expect(page).to have_content("Email has already been taken")
  end
end
