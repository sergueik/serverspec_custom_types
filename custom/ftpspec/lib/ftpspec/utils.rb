module Ftpspec
  class Utils
    def self.convert_to_octal(str)
      if str.length != 10
        raise
      end

      octal = Array.new(3)
      3.times do |i|
        octal[i] = 0
      end

      3.times do |i|
        3.times do |j|

          str_key = j + 1 + (3 * i)
          octal_key = (i % 3) + (i / 3)

          if str[str_key] == "r" then
            octal[octal_key] += 4
          end
          if str[str_key] == "w" then
            octal[octal_key] += 2
          end
          if str[str_key] == "x" then
            octal[octal_key] += 1
          end

        end
      end
      octal.join("").to_s
    end
  end
end
