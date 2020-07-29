require File.join(File.dirname(__FILE__), '..', 'remote_file')
require 'digest'

Puppet::Type.type(:remote_file).provide(:git, :parent => Puppet::Provider::RemoteFile) do
  desc "Downloads remote files"

  commands :curl => "/usr/bin/curl"

  def retrieve
    if !File.exists?(@resource[:path])
      return :absent
    end

    if @resource[:sha1hash]
      File.open(@resource[:path], 'r') do |file|
        sha1 = Digest::SHA1.new
        until file.eof?
          block = file.read(4096)
          sha1.update(block)
        end
        if sha1.hexdigest != @resource[:sha1hash]
          return :absent
        else
          return :present
        end
      end
    end

    if !File.exists?(url_path)
      return :absent
    end

    if IO.read(url_path) != @resource[:url]
      :absent
    else
      :present
    end
  end

  def create
    tmp_path = @resource[:path] + '.tmp'
    execute([command(:curl), '--location', '--output', tmp_path,
             '--silent', '--fail', '--remote-time', @resource[:url]],
            { :failonfail => true, :uid => uid, :gid => gid })
    File.rename(tmp_path, @resource[:path])
    # Make sure the mode is correct
    should_mode = @resource.should(:mode)
    unless self.mode == should_mode
      self.mode = should_mode
    end
    IO.write(url_path, @resource[:url])
  end

  def destroy
    FileUtils.rm(@resource[:path])
  end

  def mode
    if !File.exists?(@resource[:path])
      return :absent
    end
    "%o" % (File.stat(@resource[:path]).mode & 0o777)
  end

  def mode=(value)
    File.chmod(Integer("0o" + value), @resource[:path])
  end

  def uid
    Etc.getpwnam(@resource[:owner]).uid
  end

  def gid
    Etc.getgrnam(@resource[:group]).gid
  end

  def url_path
    File.join(File.dirname(@resource[:path]),
              ".#{File.basename(@resource[:path])}.url")
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
