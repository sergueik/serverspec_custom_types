require 'spec_helper'
# Copyright (c) Serguei Kouzmine

context 'verify set of patch directories' do
  # some applications notably the wso2 store patches in their staging directory
  # https://docs.wso2.com/display/Carbon420/Applying+a+Patch+to+the+Kernel
  path_to_dir = '/tmp/patches'
  patches = %w|
    patch_1001
    patch_1002
    patch_1010
    patch_1011
  |

  before(:each) do
    Specinfra::Runner::run_command( <<-EOF
      path_to_dir='#{path_to_dir}'
      patches='#{patches.join(' ')}'
      for folder in ${patches} ; do
        echo $folder
        mkdir -p "${path_to_dir}/${folder}"
      done
      mkdir -p "${path_to_dir}/dummy"
    EOF
  )
  end

  describe file(path_to_dir) do
    debug = false
    # list the patch directories
    it 'count patches in staging directory' do
      patch_glob = 'patch*' # to prevent non-patch directories from being globbed
      folder_list = Dir.glob("#{path_to_dir}/#{patch_glob}").map {|entry| entry.gsub(Regexp.new('^.*/'),'') }
      if debug
        $stderr.puts 'folders found: ' + folder_list.join(',')
      end
      $stderr.puts 'Extra folders: ' + (folder_list - patches).join(', ')
      $stderr.puts 'Missing folders: ' + (patches - folder_list).join(', ')
      (folder_list.sort == patches.sort).should be_truthy
    end
  end
end

