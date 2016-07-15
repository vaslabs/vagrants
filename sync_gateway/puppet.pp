# ===
# Install and Run Sync Gateway
# ===

$suffix = $operatingsystem ? {
    Ubuntu => ".deb",
    CentOS => ".rpm",
}

$fullUrl = "$url$suffix"
$splitter = split($fullUrl, '/')
$filename = $splitter[-1]

# Download the Sources
exec { "sync-gateway-source":
    command => "/usr/bin/wget $fullUrl",
    cwd => "/vagrant/",
    creates => "/vagrant/$filename",
    before => Package['sync-gateway'],
    timeout => 1200
}

if $operatingsystem == 'Ubuntu'{
  # Update the System
  exec { "apt-get update":
	     path => "/usr/bin"
  }
}
elsif $operatingsystem == 'CentOS'{
  case $::operatingsystemmajrelease {
    '5', '6': {
      # Ensure firewall is off (some CentOS images have firewall on by default).
      service { "iptables":
        ensure => "stopped",
        enable => false
      }
    }
    '7': {
      # This becomes 'firewalld' in RHEL7'
      service { "firewalld":
        ensure => "stopped",
        enable => false
      }
    }
  }

  # Install pkgconfig (not all CentOS base boxes have it).
  package { "pkgconfig":
    ensure => present,
    before => Package["sync-gateway"]
  }
}

# Install Sync Gateway
package { "sync-gateway":
    provider => $operatingsystem ? {
        Ubuntu => dpkg,
        CentOS => rpm,
    },
    ensure => installed,
    source => "/vagrant/$filename",
}

# Ensure the service is running if version >= 1.2
if versioncmp($version, '1.2') > -1 {
  service { "sync_gateway":
      provider => upstart,
      ensure => "running",
      require => Package["sync-gateway"]
  }
}