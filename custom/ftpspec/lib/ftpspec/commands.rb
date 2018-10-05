module Ftpspec
  class Commands

    def self.check_mode(target, expected)
      ftp = Ftpspec.get_ftp
      ftp.chdir File.dirname(target)
      ftp.list.each do |file|
        part = file.split(" ")
        if part[8] != "." && part[8] != ".." then
          current_path = ftp.pwd
          filemode = part[0]

          if current_path == "/" then
            filename = "/" + part[8]
          else
            filename = current_path + "/" + part[8]
          end

          if filename == target then
            return Ftpspec::Utils.convert_to_octal(filemode) == expected
          end
        end
      end
      return false
    end

    def self.check_file(target)
      ftp = Ftpspec.get_ftp
      ftp.chdir File.dirname(target)
      ftp.list.each do |file|
        part = file.split(" ")
        if part[8] != "." && part[8] != ".." then
          current_path = ftp.pwd
          filemode = part[0]

          if current_path == "/" then
            filename = "/" + part[8]
          else
            filename = current_path + "/" + part[8]
          end

          if filename == target then
            return filemode[0] == "-"
          end
        end
      end
      return false
    end

    def self.check_directory(target)
      ftp = Ftpspec.get_ftp
      ftp.chdir File.dirname(target)
      ftp.list.each do |file|
        part = file.split(" ")
        if part[8] != "." && part[8] != ".." then
          current_path = ftp.pwd
          filemode = part[0]

          if current_path == "/" then
            filename = "/" + part[8]
          else
            filename = current_path + "/" + part[8]
          end

          if filename == target then
            return filemode[0] == "d"
          end
        end
      end
      return false
    end

    def self.check_owner(target, expected)
      ftp = Ftpspec.get_ftp
      ftp.chdir File.dirname(target)
      ftp.list.each do |file|
        part = file.split(" ")
        if part[8] != "." && part[8] != ".." then
          current_path = ftp.pwd
          filemode = part[0]
          owner = part[2]

          if current_path == "/" then
            filename = "/" + part[8]
          else
            filename = current_path + "/" + part[8]
          end

          if filename == target then
            return owner == expected
          end
        end
      end
      return false
    end

    def self.check_group(target, expected)
      ftp = Ftpspec.get_ftp
      ftp.chdir File.dirname(target)
      ftp.list.each do |file|
        part = file.split(" ")
        if part[8] != "." && part[8] != ".." then
          current_path = ftp.pwd
          filemode = part[0]
          group = part[3]

          if current_path == "/" then
            filename = "/" + part[8]
          else
            filename = current_path + "/" + part[8]
          end

          if filename == target then
            return group == expected
          end
        end
      end
      return false
    end
  end
end
