require 'serverspec'

# NOTE: accidentally overwriting linux with  a windows spec_helper 
# would change :backend to :cmd and this
# would lead to a "No such file or directory - /cygdrive/powershell"
# error from specinfra/backend/cmd.rb

set :backend, :exec
