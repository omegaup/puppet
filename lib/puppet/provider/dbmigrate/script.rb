require File.join(File.dirname(__FILE__), '..', 'dbmigrate')

Puppet::Type.type(:dbmigrate).provide(:mysql, :parent => Puppet::Provider::DbMigrate) do
  desc "Applies a database migration with MySQL"

  commands :python3 => "/usr/bin/python3"

  def exists?
    output = execute([command(:python3)] + default_args + ['exists'],
                     { :failonfail => false })
    return output.exitstatus == 0
  end

  def latest?
    output = execute([command(:python3)] + default_args + ['latest'],
                     { :failonfail => false })
    return output.exitstatus == 0
  end

  def migrate
    args = default_args + ['migrate']
    if resource[:development_environment]
      args += ['--development-environment']
    else
      args += ['--databases', 'omegaup']
    end
    args += resource[:database_migration_args]
    python3(args)
  end

  def default_args
    scriptname = "#{resource[:name]}/stuff/db-migrate.py"
    if File.file?("#{Facter.value(:root_home)}/.my.cnf")
      [scriptname, "--mysql-config-file=#{Facter.value(:root_home)}/.my.cnf"]
    else
      [scriptname]
    end
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
