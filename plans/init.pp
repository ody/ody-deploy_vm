# @summary
#   A Bolt Plan that facilitates the creation of a virtual machine on a
#   specific selection of cloud providers by orchestrating the execution of
#   Terraform stateless by throwing away the working directoy post deploy.
#   Intended use case is as a simple VM provisioning solution within a more
#   thorough workflow which will track resources in an auxillary way.
#
# @see https://github.com/ody/ody-deploy_vm
#
# @example Greate a new virtual machine within a GCP project
#   puppet plan run deploy_vm targets=pe-primary.example.com ssh_user=provisioner network=default provider=gcp vm_name=example
#
# @param vm_image
#   Name of the image that the virtual machine will be cloned from
#
# @param vm_name
#   A predictable base name prepended to the virtual machine in addition to the
#   generated random identifier
#
# @param network
#   Network that that virtual machine will be attached to
#
# @param cloud_region
#   Cloud region when deploying to any public cloud provider
#
# @param project
#   An authenticated project where virutal machine will be provisioned when
#   deploying to Google Cloud Platform
#
# @param user
#   Remote user for validating newly provisioned host accepts connections,
#   enabling the next step of any process to proceed
#
# @param ssh_key_file
#   Path to an SSH private key which will be used when validating a virtual
#   machine running linux is ready to accept connections
#
# @param provider
#   Which cloud provider to provision a new virtual machine to, Google Cloud
#   Platform, VMWare vCenter, etc, etc.
#
plan deploy_vm(
  TargetSpec               $targets,
  Optional[String[1]]      $ssh_key_file = undef,
  Optional[String[1]]      $winrm_pw     = undef,
  Optional[String[1]]      $vm_image     = undef,
  Optional[String[1]]      $vm_name      = undef,
  Optional[String[1]]      $network      = undef,
  String[1]                $cloud_region = 'us-west1',
  String[1]                $project,
  String[1]                $remote_user,
  Enum['gcp', 'vmware']    $provider,
  Enum['linux', 'windows'] $os_type
) {

  # Dynamic generation of tfvars file from a Puppet EPP template and store it in
  # variable that can be used later
  $tfvars = $provider ? {
    'gcp'     => epp("deploy_vm/${os_type}/gcp.tfvars.epp", {
                   'project'       => $project,
                   'user'          => $remote_user,
                   'ssh_key_file'  => $ssh_key_file,
                   'winrm_pw'      => $winrm_pw,
                   'cloud_region'  => $cloud_region,
                   'vm_image'      => $vm_image,
                   'vm_name'       => $vm_name,
                   'network'       => $network
                 }),
    'vmware'  => undef,
    default   => undef
  }

  # The default case in the previous selector should never be reached and if it
  # then an implementation mistake was made, a bug discovered, or some other
  # unforeseen error occured. Plan will fail immeidately in this situation to
  # prevent additional issues.
  if $tfvars == undef {
    fail_plan('Requested variables stored in $tfvars is undefined, this should not happen and means an unforeseen error occured, plan will exit and not fulfill request')
  }

  # Store contents of Terraform manifest in a variable to keep consistent with
  # tfvars file generation
  $tffile = epp("deploy_vm/${os_type}/${provider}.tf.epp")

  # Simple function that generates a unique path name at /tmp that can be
  # created on a target to stage Terraform content within
  $tf_dir = deploy_vm::tempfile('deploy_vm-', '/tmp')

  # Leveraging a Puppet Apply block to ensure everything is appropriately and
  # in place for running Terraform
  apply($targets) {
    # Setup a temporary directory un target host to executing Terraform in
    file { $tf_dir:
      ensure => directory,
      mode   => '0700'
    }

    # Copy our virtual machine only manifest and variables file to target that
    # is used to provision requested resource
    file { "${tf_dir}/vm.tfvars": content => $tfvars }
    file { "${tf_dir}/vm.tf":     content => $tffile }
  }

  # Ensure the Terraform directory has been initialized ahead of attempting an
  # apply, which downloads all appropriate modules for deployed manifest
  run_task('terraform::initialize', $targets, { dir => $tf_dir })

  # Run Terraform to provision requested resources
  run_task('terraform::apply', $targets, {
    dir      => $tf_dir,
    var_file => "${tf_dir}/vm.tfvars",
  })

  # Capture outputs from Terrafrom so they can be passed to the next stage of
  # the resource's onboarding process
  $output = run_task('terraform::output', $targets, { dir => $tf_dir} )

  # Leverage another Puppet Apply block to do cleaup on the target, tossing
  # away generated manifests and statefile left behind by Terraform
  apply($targets) {
    file { $tf_dir:
      ensure => absent,
      force  => true
    }
  }

  # Return the importatnt value captured within Terraform outputs
  return $output.first.value['ipaddress']['value']
}
