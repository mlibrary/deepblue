module ApplicationHelper

  def self.is_local_host?
    Rails.env.development?
  end

end
