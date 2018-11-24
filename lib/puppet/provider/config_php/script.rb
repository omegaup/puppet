require File.join(File.dirname(__FILE__), '..', 'config_php')

Puppet::Type.type(:config_php).provide(:file, :parent => Puppet::Provider::ConfigPhp) do
	desc "Adds entries to config.php"

	def exists?
		s = settings
		@resource[:settings].each {|key, val|
			if !s.key?(key) || s[key] != val then
				return false
			end
		}
		return true
	end

	def create
		s = settings
		@resource[:settings].each {|key, val|
			s[key] = val
		}
		self.settings=(s)
	end

	def destroy
		s = settings
		@resource[:settings].each {|key, val|
			s.delete[key] if s.key?(key)
		}
		self.settings=(s)
	end

	def settings
		settings = {}
		if File.file?(@resource[:path])
			File.foreach(@resource[:path]) {|line|
				match = /define\('([a-zA-Z0-9_]+)',\s*'((?:\\'|[^'])*)'\);/.match(line)
				if match != nil
					settings[match[1]] = match[2].gsub(/\\\'/, '\'')
				end
			}
		end
		return settings
	end

	def settings=(s)
		newfile = !File.file?(@resource[:path])
		File.open(@resource[:path], File::WRONLY|File::CREAT|File::TRUNC) {|f|
			f.write("<?php\n")
			s.sort.map {|key, value|
				f.write("define('#{key}', '#{value.gsub(/'/, '\\\'')}');\n")
			}
		}
		if newfile
			self.owner=(@resource[:owner])
			self.group=(@resource[:group])
			self.mode=(@resource[:mode])
		end
		return true
	end

	def owner
		begin
			return Etc.getpwuid(File.stat(@resource[:path]).uid).name
		rescue
			return :absent
		end
	end

	def owner=(value)
		File.chown(Etc.getpwnam(value).uid, nil, @resource[:path])
	end

	def group
		begin
			return Etc.getgrgid(File.stat(@resource[:path]).gid).name
		rescue
			return :absent
		end
	end

	def group=(value)
		File.chown(nil, Etc.getgrnam(value).gid, @resource[:path])
	end

	def mode
		begin
			return File.stat(@resource[:path]).mode & 0o777
		rescue
			return :absent
		end
	end

	def mode=(value)
		File.chmod(value, @resource[:path])
	end
end

# vim: expandtab shiftwidth=2 tabstop=2
