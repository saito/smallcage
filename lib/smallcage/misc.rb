
# From active-support/inflector.rb
class String
  def camelize(first_letter_in_uppercase = true)
    s = self
    if first_letter_in_uppercase
      s.gsub(/\/(.?)/) { "::" + $1.upcase }.gsub(/(^|_)(.)/) { $2.upcase }
    else
      s[0..0] + s.camelize[1..-1]
    end
  end
end

