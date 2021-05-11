require 'tempfile'
Puppet::Functions.create_function(:'deploy_vm::tempfile') do
  dispatch :tempfile do
    param 'String', :name
    param 'String', :path
  end
  def tempfile(name, path)
    return Tempfile.new(name, path).path
  end
end
