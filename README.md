# lp-web-infra-azure
Deploy the Azure resources required to run the Learning Platform Web Project.
## Architecture
The ARM templates create the following Azure Cloud resources:
1. Network Security Groups
1. Virtual Network and Subnets (PAZ and Application Zone)
1. Application Gateway and its related public IP address
1. Virtual Machine (ubuntu)
1. Azure Database for MySQL server
1. Storage Account (for storing diagnostic info)
1. Bastion and its related public IP address
The Post Provisioning scripts configure the virtual machine as web server running NGINX and PHP 7.2 framework.  