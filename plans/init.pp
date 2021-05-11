plan deploy_vm(
  TargetSpec                          $targets            = 'localhost',
  Optional[String[1]]                 $ssh_pub_key_file   = undef,
  Optional[String[1]]                 $instance_image     = undef,
  Optional[String[1]]                 $network            = undef,
  String[1]                           $cloud_region       = 'us-west1',
  String[1]                           $project,
  String[1]                           $ssh_user,
) {

  $tfvars = epp('deploy_vm/tfvars.epp', {
    'project'          => $project,
    'ssh_user'         => $ssh_user,
    'ssh_pub_key_file' => $ssh_pub_key_file,
    'cloud_region'     => $cloud_region,
    'instance_image'   => $instance_image,
    'network'          => $network,
  })

  $tffile = epp('deploy_vm/tffile.epp')

  $tf_dir = deploy_vm::tempfile('deploy_vm-', '/tmp')

  apply($targets) {
    file { $tf_dir: ensure => directory, mode => '0700' }
    file { "${tf_dir}/vm.tfvars": content => $tfvars }
    file { "${tf_dir}/vm.tf": content => $tffile }
  }

  #upload_file('deploy_vm/vm.tf', "${tf_dir}/vm.tf", $targets )

  # Ensure the Terraform project directory has been initialized ahead of
  # attempting an apply
  run_task('terraform::initialize', $targets, { dir => $tf_dir })

  run_task('terraform::apply',$targets, {
    dir      => $tf_dir,
    var_file => "${tf_dir}/vm.tfvars",
  })

  $output = run_task('terraform::output', $targets, { dir => $tf_dir} )

  apply($targets) {
    file { $tf_dir: ensure => absent, force => true }
  }

  out::message($output)
}
