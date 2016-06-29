%define name emagent-preinstall  
%define version 1.0.0
%define release 12.el6


Summary: Sets the system for Oracle EM Agent install for Oracle Linux 6
Name: %{name}
Version: %{version}
Release: %{release}
Group: Applications/EMAgent
License: GPLv2
Vendor: MyVendor
Source: %{name}-%{version}.tar.gz

Provides: %{name} = %{version}

Requires(pre):/etc/redhat-release

#System requirement
Requires: glibc >= 2.3.2
Requires: libaio >= 0.3.96

BuildRoot: %{_builddir}/%{name}-%{version}-root


%description
This package installs software packages and sets system parameters required for Oracle Em Agent install for Oracle Linux Release 6
Files added: /etc/security/limits.d/emagent-limits.conf, /etc/sudoers.d/emagent.sudo, /etc/pam.d/emagent, /etc/logrotate.d/emagentlog.lr.


%pre
# Check for sufficient diskspace
if [ -d /opt/emagent ]; then
  diskspace=`df -k /opt/emagent | grep % | tr -s " " | cut -d" " -f4 | tail -1`
  diskspace=`expr $diskspace / 1024`
  if [ $diskspace -lt 1024 ]; then
    echo "You have insufficient diskspace in the destination directory (/opt/emagent) to
install Oracle Agent 12c. The installation requires at least 2 GB free on this disk."
    exit 1
  fi
fi


%prep
echo RPM_BUILD_ROOT=$RPM_BUILD_ROOT
%setup -q


%build


%install
rm -rf $RPM_BUILD_ROOT

mkdir -p -m 755 $RPM_BUILD_ROOT/etc/security/limits.d
mkdir -p -m 755 $RPM_BUILD_ROOT/etc/logrotate.d
mkdir -p -m 755 $RPM_BUILD_ROOT/etc/pam.d
mkdir -p -m 750 $RPM_BUILD_ROOT/etc/sudoers.d

install emagent-limits.conf $RPM_BUILD_ROOT/etc/security/limits.d/emagent-limits.conf
install emagent.sudo $RPM_BUILD_ROOT/etc/sudoers.d/emagent.sudo
install emagent $RPM_BUILD_ROOT/etc/pam.d/emagent
install emagentlog.lr $RPM_BUILD_ROOT/etc/logrotate.d/emagentlog.lr

ln -f -s /etc/sysconfig/%{name}/emagent-preinstall-verify $RPM_BUILD_ROOT/usr/bin/emagent-preinstall-verify 

/bin/grep -i "^#includedir /etc/sudoers.d" /etc/sudoers > /dev/null 2>&1
if [ $? -ne 0 ]; then
  echo "#includedir /etc/sudoers.d" >> /etc/sudoers
fi

if test -f /sys/kernel/mm/transparent_hugepage/enabled; then
  echo never > /sys/kernel/mm/redhat_transparent_hugepages/enabled
fi
if test -f /sys/kernel/mm/transparent_hugepage/defrag; then
  echo never > /sys/kernel/mm/transparent_hugepage/defrag
fi


%clean
rm -rf $RPM_BUILD_ROOT


%post
chmod 644 /etc/security/limits.d/emagent-limits.conf
chmod 644 /etc/pam.d/emagent
chmod 644 /etc/logrotate.d/emagentlog.lr
chmod 440 /etc/sudoers.d/emagent.sudo

%preun


%postun


%files
%defattr(-,root,root)
/etc/security/limits.d/emagent-limits.conf
/etc/pam.d/emagent
/etc/logrotate.d/emagentlog.lr
/etc/sudoers.d/emagent.sudo

%changelog
* Thu Apr 04 2014 Stuart Wong <cgs.wong@gmail.comm> [1.0-1.el6]
 - Created based on 12cR2 preinstall. 
