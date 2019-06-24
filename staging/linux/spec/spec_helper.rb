require 'serverspec'

# This spec_helper.rb is for running serverspec locally on a Linux box

set :backend, :exec
# NOTE: accidentally overwriting linux spec_helper.rb with the windows one
# would likely change :backend to :cmd and this
# would manifest itself through the "No such file or directory - /cygdrive/powershell"
# exception from specinfra/backend/cmd.rb

