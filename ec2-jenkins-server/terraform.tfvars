# DEFINE ALL YOUR VARIABLES HERE

instance_type = "t2.medium"
ami           = "ami-0e35ddab05955cf57"   # Ubuntu 24.04
key_name      = "ec2key"                     # Replace with your key-name without .pem extension
volume_size   = 8
region_name   = "us-east-1"
server_name   = "JENKINS-SERVER"

# Note: 
# a. First create a pem-key manually from the AWS console
# b. Copy it in the same directory as your terraform code
