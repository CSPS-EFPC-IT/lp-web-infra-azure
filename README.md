# lp-web-infra-azure
Deploy the Azure resources required to run the Learning Platform Web Project.
## Architecture
This ARM template creates the following Azure Cloud resources:
1. Network Security Groups (for PAZ and Application subnets)
1. Virtual Network and Subnets (Bastion, PAZ and Application)
1. Application Gateway and its related public IP address
1. Virtual Machine (ubuntu 18.04)
1. Azure Database for MySQL server
1. Storage Account (for storing diagnostic info)
1. Bastion and its related public IP address

The Post Provisioning scripts configure the virtual machine as web server running NGINX and PHP 7.3 framework.
## Pre-requisites
The following resources must exist prior to the deployment of the current ARM templates and scripts:
1. A __Resource Group__
1. A __Key Vault__ with a valid certificate (will be used by the Application Gateway for SSL/TLS offload)
1. A __User Assigned Managed Identity__ with "GET" permissions on both Secrets and Certificates stored in the Key Vault where the Application Gateway certificate is stored
