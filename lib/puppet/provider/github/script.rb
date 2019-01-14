require File.join(File.dirname(__FILE__), '..', 'github')
require 'pathname'

Puppet::Type.type(:github).provide(:git, :parent => Puppet::Provider::GitHub) do
  desc "Manages git repositories"

  commands :git => "/usr/bin/git"

  def exists?
    if !Pathname(@resource[:path]).join('.git').directory?
      return false
    end
    Dir.chdir(@resource[:path]) do
      @resource[:remotes].to_h.each do |name, repo|
        if !Pathname(@resource[:path]).join('.git/remotes/refs').join(name).directory?
          return false
        end
      end
    end
    return true
  end

  def latest?
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'fetch', '-q',
               @resource[:origin], @resource[:branch]],
              { :failonfail => true, :uid => uid, :gid => gid })
      begin
        head, fetch_head = execute([command(:git), 'rev-parse',
                                    'HEAD^{commit}', 'FETCH_HEAD^{commit}'],
                                   { :failonfail => true, :uid => uid,
                                     :gid => gid }).lines()
        if head != fetch_head
          return false
        end
      rescue Puppet::ExecutionFailure
        return false
      end
      @resource[:remotes].to_h.each do |name, repo|
        if !Pathname(@resource[:path]).join('.git/remotes/refs').join(name).directory?
          return false
        end
      end
    end
    return true
  end

  def common_sync
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'submodule', 'update', '--init', '--recursive'],
             { :failonfail => true, :uid => uid, :gid => gid })
      @resource[:remotes].to_h.each do |name, repo|
        if !Pathname(@resource[:path]).join('.git/remotes/refs').join(name).directory?
          execute([command(:git), 'remote', 'add', name,
                   "https://github.com/#{repo}.git"],
                  { :failonfail => false, :uid => uid, :gid => gid })
        end
        execute([command(:git), 'fetch', '-q', name],
                { :failonfail => true, :uid => uid, :gid => gid })
      end
    end
  end

  def reset
    if !Pathname(@resource[:path]).join('.git').directory?
      create
      return
    end
    Dir.chdir(@resource[:path]) do
      execute([command(:git), 'fetch', '-q',
               @resource[:origin], @resource[:branch]],
              { :failonfail => true, :uid => uid, :gid => gid })
      execute([command(:git), 'reset', '--hard', 'FETCH_HEAD^{commit}'],
              { :failonfail => true, :uid => uid, :gid => gid })
      common_sync
    end
  end

  def create
    Dir.chdir(@resource[:path]) do
      if !Pathname(@resource[:path]).join('.git').directory?
        execute([command(:git), 'clone',
               "https://github.com/#{@resource[:repo]}.git",
               '-o', @resource[:origin], '-b', @resource[:branch], '.'],
               { :failonfail => true, :uid => uid, :gid => gid })
      end
      common_sync
    end
  end

  def destroy
    FileUtils.remove_dir(@resource[:path])
  end

  def uid
    Etc.getpwnam(@resource[:owner]).uid
  end

  def gid
    Etc.getgrnam(@resource[:group]).gid
  end
end

# vim: expandtab shiftwidth=2 tabstop=2
