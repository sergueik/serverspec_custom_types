require "spec_helper"

describe "Ftpspec::Commands" do

  before :all do
    class Ftp
      def chdir(target)
        "/httpdocs"
      end
      def list
        [
          "drwxr-xr-x  25 owner_name group_name      4096 Aug  3 19:57 .", 
          "drwxr-xr-x  13 root     root         4096 Oct 22  2012 ..",
          "-rw-r--r--   1 owner_name group_name      26482 Jul 19  2010 index.php",
          "drwxr-xr-x   4 owner_name group_name       4096 Oct 17  2010 dir"
        ]
      end
      def pwd
      end
    end
    @ftp = Ftp.new
  end

  describe ".check_mode" do
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_mode("/httpdocs/index.php", "644")
      expect(actual).to be true
    end
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_mode("/index.php", "644")
      expect(actual).to be true
    end
    it "returns false" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_mode("/httpdocs/index.php", "645")
      expect(actual).to be false
    end
  end

  describe ".check_file" do
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_file("/httpdocs/index.php")
      expect(actual).to be true
    end
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_file("/index.php")
      expect(actual).to be true
    end
    it "returns false" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_file("/httpdocs/dir")
      expect(actual).to be false
    end
  end

  describe ".check_directory" do
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_directory("/httpdocs/dir")
      expect(actual).to be true
    end
    it "returns true" do
      allow(@ftp).to receive(:pwd) { "/" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_directory("/dir")
      expect(actual).to be true
    end
    it "returns false" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_directory("/httpdocs/index.php")
      expect(actual).to be false
    end
  end

  describe ".check_owner" do
    it "returns true if owner name is valid" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_owner("/httpdocs/index.php", "owner_name")
      expect(actual).to be true
    end
    it "returns true if owner name is valid" do
      allow(@ftp).to receive(:pwd) { "/" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_owner("/index.php", "owner_name")
      expect(actual).to be true
    end
    it "returns false if owner name is invalid" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_owner("/httpdocs/index.php", "invalid_owner")
      expect(actual).to be false
    end
  end

  describe ".check_group" do
    it "returns true if group name is valid" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_group("/httpdocs/index.php", "group_name")
      expect(actual).to be true
    end
    it "returns true if group name is valid" do
      allow(@ftp).to receive(:pwd) { "/" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_group("/index.php", "group_name")
      expect(actual).to be true
    end
    it "returns false if group name is invalid" do
      allow(@ftp).to receive(:pwd) { "/httpdocs" }
      allow(Ftpspec).to receive(:get_ftp) { @ftp }
      actual = Ftpspec::Commands.check_group("/httpdocs/index.php", "invalid_owner")
      expect(actual).to be false
    end
  end
end
