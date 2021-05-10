require 'tmpdir'
Puppet::Functions.create_function(:'deploy_vm::with_tempdir') do
  dispatch :with_tempdir do
    param 'String', :name
    block_param 'Callable[1, 1]', :block
  end
  def with_tempdir(name)
    Dir.mktmpdir(name) do |dir|
      yield dir
    end
  end
end
