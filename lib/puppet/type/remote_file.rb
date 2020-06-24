Puppet::Type.newtype(:remote_file) do
  @doc = "Downloads remote files"

  ensurable do
    def retrieve
      provider.retrieve
    end

    def insync?(is)
      return is == should
    end

    newvalue :present do
      provider.create
    end

    newvalue :absent do
      provider.destroy
    end
  end

  newparam(:path, :namevar => true) do
    desc "Path of the file to be downloaded"
  end

  newparam(:url) do
    desc "The URL from which the file will be downloaded"
    isrequired
  end

  newparam(:sha1hash) do
    desc "SHA1 hash of the file"
  end

  newproperty(:mode) do
    desc "The mode of the file"
    defaultto "0640"
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
