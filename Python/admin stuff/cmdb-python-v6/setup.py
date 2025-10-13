
from setuptools import setup, find_packages

setup(
    name="cmdb-python-toolkit",
    version="6.0.0",
    description="CMDB inventory and discovery toolkit for hybrid environments",
    author="CMDB Python Toolkit Maintainers",
    packages=find_packages(exclude=("tests",)),
    install_requires=[
        "pyyaml>=6.0.1",
        "jinja2>=3.1.4",
        "psutil>=5.9.8",
        "pywinrm>=0.4.3",
        "paramiko>=3.4.0",
        "azure-identity>=1.17.1",
        "azure-mgmt-resource>=23.1.0",
        "azure-mgmt-compute>=33.0.0",
        "ldap3>=2.9.1",
        "pyvmomi>=8.0.3.0",
        "requests>=2.32.3",
        "SQLAlchemy>=2.0.31",
        "rich>=13.7.1",
        "dnspython>=2.6.1",
    ],
    python_requires=">=3.10",
    include_package_data=True,
)
