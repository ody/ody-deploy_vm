# @summary
#   A basic function that replicates Ruby's generation of tamporary
#   file/directory paths for use in Puppet Bolt for this module's use case of
#   deploying resources via Terraform.
#
# @see https://github.com/ody/ody-deploy_vm
#
# @example Create a random path for usage by Bolt
#
#    $working_dir = deploy_vm::temppath('puppet-', '/tmp')
#    file { $working_dir:
#      ensure => directory,
#      mode   => '0700'
#    }
#
# @param name
#   A value that will act as a prefix to the path destination
#
# @param path
#   The base directory where temporary files/directories are stored
#
require 'tmpdir'
Puppet::Functions.create_function(:'deploy_vm::temppath') do
  dispatch :temppath do
    param 'String', :name
    param 'String', :path
  end
  def temppath(name, path)
    return Dir::Tmpname.create(name, path) { || }
  end
end
