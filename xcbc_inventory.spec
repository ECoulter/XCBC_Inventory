Name:		xcbc_inventory
Version:	0.2
Release:	0
Summary:	simple cluster inventory rpm

License:	MIT
Source0:	%{name}.tar.gz
Group:  	System/base
Vendor:		XSEDE

BuildArch:	noarch
BuildRoot:	%{_tmppath}/%{name}-%{version}-build)
Prefix:         /opt

#Requires(pre): 	/usr/sbin/useradd, /usr/bin/getent

%description
This package provides a simple inventory script for taking "roll" of XCBC 
cluster build, and sending some basic information (number of nodes, processor 
speed, RAM, cluster name) back to XSEDE for accounting purposes.

%pre
#/usr/bin/getent group xcbc_checker || /usr/sbin/groupadd -r xcbc_checker
/usr/bin/getent passwd xcbc_checker || /usr/sbin/useradd -d /opt/xcbc_inventory -s /bin/bash xcbc_checker
grep "DenyUsers xcbc_checker" /etc/ssh/sshd_config || sed -i '13 i DenyUsers xcbc_checker' /etc/ssh/sshd_config
#exit 0 #to prevent install failure if can't add that user?

%prep
%setup -n %{name}

%build

%install
mkdir -p $RPM_BUILD_ROOT/opt/xcbc_inventory/
install -m 700 simple_inventory.sh $RPM_BUILD_ROOT/opt/xcbc_inventory/

%clean
rm -rf $RPM_BUILD_ROOT
rm -rf %{_tmppath}/%{name}
rm -rf %{_topdir}/BUILD/%{name}


%files
%defattr(-,root,root)
%attr(700, xcbc_checker, xcbc_checker) /opt/xcbc_inventory/simple_inventory.sh

%post 
chown xcbc_checker:xcbc_checker $RPM_INSTALL_PREFIX/xcbc_inventory
echo -e "if [ -z \"\$PS1\" ]; #xcbc_inventory - check if interactive shell!
then #xcbc_inventory
  sleep 0 #xcbc_inventory do nothing if non-interactive
else #xcbc_inventory
  if [ \$(rocks list host | grep compute | wc -l) != 0 ]; #checking if compute nodes prior to running xcbc_inventory
  then #xcbc_inventory
    if [ -e $RPM_INSTALL_PREFIX/xcbc_inventory/remove ]; 
    then #xcbc_inventory
      rm -f $RPM_INSTALL_PREFIX/xcbc_inventory/remove
      sed -i '/xcbc_inventory/d' $HOME/.bashrc
    else #xcbc_inventory
      su - xcbc_checker $RPM_INSTALL_PREFIX/xcbc_inventory/simple_inventory.sh
    fi #xcbc_inventory remove 
  fi #xcbc_inventory compute nodes present
fi #xcbc_inventory interactive check" >> $HOME/.bashrc

%postun
userdel -f xcbc_checker
rm -rf $RPM_INSTALL_PREFIX/xcbc_inventory
sed -i '/xcbc_inventory/d' $HOME/.bashrc
sed -i '/xcbc_checker/d' /etc/ssh/sshd_config

%changelog
 * Mon Jun 8 2015 	John Coulter
 - 0.1 Initial Version Release 0
 - 0.1.1 Initial Version changed user to xcbc_checker Release 0
 - 0.1.2 Changed script to reflect encounter with heterogeneous cluster 
 - 0.2 Removed cron; added interactive script in case port 25 is blocked
