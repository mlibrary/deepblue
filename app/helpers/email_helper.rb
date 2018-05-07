module EmailHelper

  def self.notification_email
    Rails.configuration.notification_email
  end

  def self.user_email
    Rails.configuration.user_email
  end

  def self.user_email_from( current_user, user_signed_in: true )
    return nil unless user_signed_in
    user_email = nil
    unless current_user.nil?
      #Rails.logger.debug "current_user=#{current_user}"
      #Rails.logger.debug "current_user.name=#{current_user.name}"
      #Rails.logger.debug "current_user.email=#{current_user.email}"
      user_email = current_user.email
    end
    user_email
  end

end