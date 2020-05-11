Puppet::Type.newtype(:dbmigrate) do
  @doc = "Apply a database migration"

  ensurable do
    def retrieve
      if !provider.exists?
        return :absent
      end
      return provider.latest? ? :latest : :present
    end

    def insync?(is)
      return is == should
    end

    newvalue :latest do
      provider.migrate
    end
  end

  newparam(:root, :namevar => true) do
    desc "Root of the omegaUp checkout"
  end

  newparam(:development_environment) do
    desc "Whether this is a development environment"
  end

  newparam(:database_migration_args) do
    desc "Additional arguments to the migration script"
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
