
module LinkBehavior

  def generate_download_key
    (Digest::SHA2.new << rand(1_000_000_000).to_s).to_s
  end

  def path_eq?( other_path )
    path_strip_locale( path ) == path_strip_locale( other_path )
  end

  def path_strip_locale( the_path )
    return the_path if the_path.blank?
    if the_path =~ /^(.+)\?.+/
      return Regexp.last_match[1]
    end
    return the_path
  end

end
