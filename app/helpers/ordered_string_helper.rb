module OrderedStringHelper

  class DeserializeError < Exception
  end

  #
  # convert a serialized array to a normal array of values
  # assumes values are stored as json converted to strings
  # a failure to deserialize throws a DeserializeError,
  # the exact reason for failure is ignored
  #
  def self.deserialize( serialized_string_containing_an_array )
    if serialized_string_containing_an_array.start_with?('[')
      begin
        arr = ActiveSupport::JSON.decode serialized_string_containing_an_array
        if arr.kind_of?( Array )
          return arr
        end
      rescue ActiveSupport::JSON.parse_error
        # ignore and fall through
      end
    end
    raise OrderedStringHelper::DeserializeError
  end

  #
  # serialize a normal array of values to an array of ordered values
  #
  def self.serialize( arr )
    serialized_string_containing_an_array = ActiveSupport::JSON.encode( arr ).to_s
    return serialized_string_containing_an_array
  end

end