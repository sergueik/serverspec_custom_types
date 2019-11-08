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

  describe command( <<-EOF
    grep -E '\\[[a-zA-Z0-9]+\\]' '#{rc_file}'
  EOF
  ) do
    [
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
      its(:stdout) { should contain "[#{section}]" }
    end
  end


  # TODO: add section discovery in before(:all)

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
    # tac file | sed -n '1,/^$/{/./p}' | tac
    # see also: https://toster.ru/q/682041
    #
    describe command( <<-EOF
      grep -v '^ *#' '#{rc_file}' | awk 'BEGIN{RS="\\n\\n+"; OFS="\\n"} /#{section}/ {print $0}'
    EOF
    ) do
      its(:stdout) { should contain /Disabled=true/ }
    end
  end
  # TODO: define
  # check_exists(key_name)
  # check_has_property(key_name, key_property)
  # check_has_value(key_name, key_property, key_value)

  {
    'JPEGThumbnailer' => {
     #  empty
    } ,
    'CoverThumbnailer' => {
	  'Locations' => '~/movies',
	  'Priority' => 3,
    },
  }.each do |section,entries|
    describe command( <<-EOF
      grep -v '^ *#' '#{rc_file}' | awk 'BEGIN{RS="\\n\\n+"; OFS="\\n"} /#{section}/ {print $0}'
    EOF
    ) do
      entries.each do |key,value|
        # verbatim
	    its(:stdout) { should contain "#{key}=#{value}" }
        # expression
	    its(:stdout) { should match Regexp.new(Regexp.escape( "#{key}=#{value}" )) }
      end
    end
  end
end

