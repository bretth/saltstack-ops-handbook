# https://docs.saltstack.com/en/latest/ref/states/writing.html

# the short form for calling a python module function
# Ubuntu 16.04 pip needs python-setuptools for some packages
python-setuptools:  # globally unique id and name argument
  pkg.installed # salt module.function
# equivalent of salt.states.pkg.installed('python-setuptools')

# the preferred longer form 
enable_saltstack_to_install_python-pip_packages: # globally unique id
  pkg.installed: # salt module.function
    - name: python-pip  # name argument
 
enable_saltstack_to_add_external_apt_packages: 
  pkg.installed:
    - name: python-apt