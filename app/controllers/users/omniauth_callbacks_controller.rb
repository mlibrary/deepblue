# this file is for IU authentication only

class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def cas
    @user = User.find_for_iu_cas(request.env["omniauth.auth"])
    if @user.persisted?
      sign_in_and_redirect @user, :event => :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, :kind => "IU CAS") if is_navigational_format?
    else
      session["devise.cas_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end
end