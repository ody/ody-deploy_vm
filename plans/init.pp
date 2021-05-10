plan deploy_vm(
  TargetSpec                          $targets            = 'localhost',
  Optional[String[1]]                 $ssh_pub_key_file   = undef,
  Optional[String[1]]                 $instance_image     = undef,
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
  })

  $tf_manifest = epp('deploy_vm/vm.tf.epp')

  $apply = deploy_vm::with_tempdir('deploy_vm-') |$tf_dir| {

    file::write("${tf_dir}/vm.tfvars", $tfvars)

    file::write("${tf_dir}/vm.tf", $tf_manifest)

    # Ensure the Terraform project directory has been initialized ahead of
    # attempting an apply
    run_task('terraform::initialize', $targets, dir => $tf_dir)

    run_plan('terraform::apply',
      dir           => $tf_dir,
      return_output => true,
      var_file      => "${tf_dir}/vm.tfvars",
    )
  }

  out::message($apply)
}
