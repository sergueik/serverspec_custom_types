require "spec_helper"

describe ".convert_to_octal" do
  actual = Ftpspec::Utils.convert_to_octal "-rwxrwxrwx"
  it "should be 777" do
    expect(actual).to eq("777")
  end
end

describe ".convert_to_octal" do
  actual = Ftpspec::Utils.convert_to_octal "-rw-r--r--"
  it "should be 644" do
    expect(actual).to eq("644")
  end
end

describe ".convert_to_octal" do
  actual = Ftpspec::Utils.convert_to_octal "----------"
  it "should be 000" do
    expect(actual).to eq("000")
  end
end

describe ".convert_to_octal" do
  it "should raise error" do
    expect do
      Ftpspec::Utils.convert_to_octal("---------")
    end.to raise_error
  end
end
