maintainer        "Opscode, Inc."
maintainer_email  "cookbooks@opscode.com"
license           "Apache 2.0"
description       "Installs subversion"
version           "0.8.3"

%w{ redhat centos fedora ubuntu debian }.each do |os|
  supports os
end

recipe "subversion", "Includes the client recipe."
recipe "subversion::client", "Subversion Client installs subversion and some extra svn libs"
