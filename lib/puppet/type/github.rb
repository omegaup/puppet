Puppet::Type.newtype(:github) do
  @doc = "Manages GitHub repositories"

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
      provider.reset
    end

    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end

  newparam(:path, :namevar => true) do
    desc "Path of the checkout"
  end

  newparam(:repo) do
    desc "The repository"
    isrequired
  end

  newparam(:origin) do
    desc "The name of the origin"
    defaultto 'upstream'
  end

  newparam(:branch) do
    desc "The branch to clone"
    defaultto 'main'
  end

  newparam(:remotes) do
    desc "Any additional remotes"
    defaultto {}
  end

  newparam(:owner) do
    desc "The file's owner"
    isrequired
  end

  newparam(:group) do
    desc "The file's owner"
    isrequired
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
