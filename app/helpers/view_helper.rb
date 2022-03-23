
module ViewHelper

  def self.to_date(str)
    return nil if str.blank?
    return DateTime.strptime( str, "%Y-%m-%d %H:%M:%S" ) if str =~ /\d\d\d\d\-\d\d?\-\d\d? \d\d?:\d\d:\d\d/
    return DateTime.strptime( str, "%Y-%m-%d" ) if str =~ /\d\d\d\d\-\d\d\-\d\d/
    return DateTime.strptime( str, "%m/%d/%Y" ) if str =~ /\d\d?\/\d\d?\/\d\d\d\d/
    return DateTime.strptime( str, "%m-%d-%Y" ) if str =~ /\d\d?\-\d\d?\-\d\d\d\d/
    return DateTime.strptime( str, "%m/%d/%Y" ) if str =~ /\d\d?\/\d\d?\/\d\d\d\d/
    return DateTime.strptime( str, "%Y" ) if str =~ /\d\d\d\d/
    return DateTime.parse( str )
  end

end
