# Update packages
sudo apt-get update -y

# Install the unzip (if not installed)
sudo apt-get install -y unzip curl

# Download latest Terraform
curl -LO https://releases.hashicorp.com/terraform/1.7.7/terraform_1.7.7_linux_amd64.zip

# Unzip the downloaded file
unzip terraform_1.7.7_linux_amd64.zip

# Move terraform binary to /usr/local/bin
sudo mv terraform /usr/local/bin/

# Verify installation for version
terraform -v
