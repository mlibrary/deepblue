# spec/support/features/session_helpers.rb
module Features
  module SessionHelpers

    # SESSION_HELPERS_DEBUG_VERBOSE = true
    #
    # def sign_in(who = :user)
    #   sign_out
    #   sleep 10 if SESSION_HELPERS_DEBUG_VERBOSE
    #   user = who.is_a?(User) ? who : build(:user).tap(&:save!)
    #
    #   ::Deepblue::LoggingHelper.bold_puts [ ::Deepblue::LoggingHelper.here,
    #                                         "user=#{user}",
    #                                         "new_user_session_path=#{new_user_session_path}",
    #                                         "" ] if SESSION_HELPERS_DEBUG_VERBOSE
    #
    #   visit new_user_session_path
    #   sleep 10 if SESSION_HELPERS_DEBUG_VERBOSE
    #   fill_in 'Email', with: user.email
    #   fill_in 'Password', with: user.password
    #   sleep 10 if SESSION_HELPERS_DEBUG_VERBOSE
    #   click_button 'Log in'
    #   expect(page).not_to have_text 'Invalid email or password.'
    # end
    #
    # def sign_out
    #   # logout
    #   visit '/logout'
    #   sleep 10 if SESSION_HELPERS_DEBUG_VERBOSE
    #   click_button 'Log Out'
    # end

  end

end
