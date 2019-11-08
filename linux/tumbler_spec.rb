require 'spec_helper'

# NOTE: removing tumbler package under Xubuntu likely lead to removal of xubuntu-desktop metapackage - varies with Ubuntu release
context 'Tumbler Configuration' do

  rc_file = '/etc/xdg/tumbler/tumbler.rc'
  describe file rc_file do
    its(:content) { should_not match /Disabled=false/ }
  end
  describe command( <<-EOF
    grep -A4 '\[OdfThumbnailer\]' '#{rc_file}' | grep 'Disabled'
  EOF
  ) do
    its(:stdout) { should_not contain /Disabled=false/ }
  end
  # see also: https://github.com/pixelb/crudini/blob/master/crudini
  # see also: https://stackoverflow.com/questions/6318809/how-do-i-grab-an-ini-value-within-a-shell-script
  #
  # sed -nr "/^\'JPEGThumbnailer\]/ { :l /^Disabled' ]*=/ { s/.*=' ]*//; p; q;}; n; b l;}" /etc/xdg/tumbler/tumbler.rc
  # true
  # TODO: before(:all)
  # grep -E '\[[a-zA-Z0-9]+\]' /etc/xdg/tumbler/tumbler.rc
  [
    # 'TypeNameOfPlugin',
    'JPEGThumbnailer',
    'PixbufThumbnailer',
    'RawThumbnailer',
    'CoverThumbnailer',
    'FfmpegThumbnailer',
    'GstThumbnailer',
    'FontThumbnailer',
    'PopplerThumbnailer',
    'OdfThumbnailer',
  ].each do |section|
    # NOTE: the following will break apart by section but loses section name
    # awk 'BEGIN{RS="\''a-zA-z0-9]+\]"} {print $1 " " $2}' /etc/xdg/tumbler/tumbler.rc
    # NOTE: for blank line the correct RS is the \n\n+ not the \n+
    describe command( <<-EOF
      grep -v '^ *#' '#{rc_file}' | awk 'BEGIN{RS="\\n\\n+"} /#{section}/ {print $1 "\\n" $2 "\\n" $3 "\\n" $4 "\\n" $5 "\\n" $6 "\\n" $7 "\\n" $8 "\\n" $9}'
    EOF
    ) do
      its(:stdout) { should contain /Disabled=true/ }
    end
  end
end

