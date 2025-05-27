terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.67.0"
    }
  }
}

provider "aws" {
  region = var.region_name
}

# STEP1: CREATE SG
resource "aws_security_group" "my-sg-docker" {
  name        = "DOCKER-SERVER-SG"
  description = "Docker Server Ports"
  
  # Port 22 is required for SSH Access
  ingress {
    description     = "SSH Port"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 80 is required for HTTP
  ingress {
    description     = "HTTP Port"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Port 9000 is required for SonarQube
  ingress {
    description     = "SonarQube Port"
    from_port       = 9000
    to_port         = 9000
    protocol        = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }  

  # Define outbound rules to allow all
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# STEP2: CREATE EC2 USING PEM & SG
resource "aws_instance" "my-ec2-docker" {
  ami           = var.ami   
  instance_type = var.instance_type
  key_name      = var.key_name        
  vpc_security_group_ids = [aws_security_group.my-sg-docker.id]
  subnet_id = "subnet-00492b26b298d1aa0"
  root_block_device {
    volume_size = var.volume_size
  }
  
  tags = {
    Name = var.server_name
  }
  
    # USING REMOTE-EXEC PROVISIONER TO INSTALL PACKAGES
  provisioner "remote-exec" {
    # ESTABLISHING SSH CONNECTION WITH EC2
    connection {
      type        = "ssh"
      private_key = file("./key.pem") # replace with your key-name 
      user        = "ubuntu"
      host        = self.public_ip
    }

    inline = [
      # Install AWS CLI
      # Ref: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
      "sudo apt install unzip -y",
      "curl 'https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip' -o 'awscliv2.zip'",
      "unzip awscliv2.zip",
      "sudo ./aws/install",

      # Install Docker
      # Ref: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
      "sudo apt-get update -y",
      "sudo apt-get install -y ca-certificates curl",
      "sudo install -m 0755 -d /etc/apt/keyrings",
      "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo tee /etc/apt/keyrings/docker.asc",
      "sudo chmod a+r /etc/apt/keyrings/docker.asc",
      "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
      "sudo apt-get update -y",
      "sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin",
      "sudo usermod -aG docker ubuntu",
      "sudo chmod 777 /var/run/docker.sock",
      "docker --version",

      # Install SonarQube (as container)
      "docker run -d --name sonar -p 9000:9000 sonarqube:lts-community",

      # Output
      "echo 'Access SonarQube Server here --> http://'$ip':9000'",
      "echo 'SonarQube Username & Password: admin'",
    ]
  }
}  

# STEP3: GET EC2 USER NAME AND PUBLIC IP 
output "SERVER-SSH-ACCESS" {
  value = "ubuntu@${aws_instance.my-ec2-docker.public_ip}"
}

# STEP4: GET EC2 PUBLIC IP 
output "PUBLIC-IP" {
  value = "${aws_instance.my-ec2-docker.public_ip}"
}

# STEP5: GET EC2 PRIVATE IP 
output "PRIVATE-IP" {
  value = "${aws_instance.my-ec2-docker.private_ip}"
