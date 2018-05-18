#
# Install puppet rpm repo and puppet-agent
#
echo "Installing puppet-agent"
rpm -q puppet-release > /dev/null || yum install -y --nogpgcheck http://yum.puppetlabs.com/puppet/puppet-release-el-7.noarch.rpm
rpm -q puppet-agent > /dev/null || yum install -y --nogpgcheck puppet-agent
rpm -q git > /dev/null || yum install -y --nogpg git

#
# Install r10k. We need this to download the correct set of puppet modules
#
if ! /opt/puppetlabs/puppet/bin/gem which r10k > /dev/null 2>&1
then
  echo 'Installing required gems'
  /opt/puppetlabs/puppet/bin/gem install r10k --no-rdoc --no-ri
fi

cd /vagrant
#
# Copy netrc file if it exists
#
if [ -e /vagrant/.netrc ]
then
  cp /vagrant/.netrc ~
fi

echo 'Installing required puppet modules'
/opt/puppetlabs/puppet/bin/r10k puppetfile install -c /vagrant/r10k.yaml

#
# Setup hiera search and backend. We need this to config our systems
#
echo 'Setting up hiera directories'
dirname=/etc/puppetlabs/code/environments/production/hieradata
if [ -d $dirname ]; then
  rm -rf $dirname
else
  rm -f $dirname
fi
ln -sf /vagrant/hieradata /etc/puppetlabs/code/environments/production
rm -f /etc/puppetlabs/code/environments/production/hiera.yaml
ln -sf /vagrant/hiera.yaml /etc/puppetlabs/code/environments/production

#
# Configure the puppet path's
#
echo 'Setting up Puppet module directories'
dirname=/etc/puppetlabs/code/environments/production/modules
if [ -d $dirname ]; then
  rm -rf $dirname
else
  rm -f $dirname
fi
ln -sf /vagrant/modules /etc/puppetlabs/code/environments/production

echo 'Setting up Puppet manifest directories'
dirname=/etc/puppetlabs/code/environments/production/manifests
if [ -d $dirname ]; then
  rm -rf $dirname
else
  rm -f $dirname
fi
ln -sf /vagrant/manifests /etc/puppetlabs/code/environments/production
