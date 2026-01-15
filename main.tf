data "aws_ami" "app_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["bitnami-tomcat-*-x86_64-hvm-ebs-nami"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["979382823631"] # Bitnami
}

data "aws_vpc" "default" {
  default = true                # Constrain to be the default VPC
}

module "blog_vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "dev"
  cidr = "10.0.0.0/16"

  azs             = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  # private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  # enable_nat_gateway = true
  # enable_vpn_gateway = true

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_instance" "blog" {
  ami                   = data.aws_ami.app_ami.id
  instance_type         = var.instance_type
  # vpc_security_group_ids = [aws_security_group.blog.id]
  vpc_security_group_ids = [module.blog_sg.security_group_id]

  subnet_id = module.blog_vpc.public_subnets[0]

  tags = {
    Name = "HelloWorld"
  }
}

module "alb" {
  source = "terraform-aws-modules/alb/aws"
  
  name    = "blog-alb"                      # WAS "my-alb"

  vpc_id  = module.blog_vpc.vpc_id          # WAS "vpc-abcde012"
  subnets = module.blog_vpc.public_subnets  # WAS ["subnet-abcde012", "subnet-bcde012a"]
  security_groups = module.blog_sg.security_group_id

  # access_logs = {
  #   bucket = "my-alb-logs"
  # }

  target_groups = [
    {
      name_prefix      = "blog-"
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
      targets = {
        my_target = {
          target_id = aws_instance.blog.id
          port = 80
        }
        # my_other_target = {
        #  target_id = "i-a1b2c3d4e5f6g7h8i"
        #  port = 8080
        # }
      }
    }
  ]

  # https_listeners = [
  #   {
  #     port               = 443
  #     protocol           = "HTTPS"
  #     certificate_arn    = "arn:aws:iam::123456789012:server-certificate/test_cert-123456789012"
  #     target_group_index = 0
  #   }
  # ]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  tags = {
    Environment = "dev"
  }
}

module "blog_sg" {
  source          = "terraform-aws-modules/security-group/aws"
  version         = "5.3.1"
  name            = "blog"
  use_name_prefix = false
  description     = "SG for webserver created using the security_group module"

  # vpc_id        = data.aws_vpc.default.id  # set ID is the default vpc
  vpc_id              = module.blog_vpc.vpc_id
  ingress_rules       = ["http-80-tcp", "https-443-tcp"]
  ingress_cidr_blocks = ["0.0.0.0/0"]
  egress_rules        = ["all-all"] 
  egress_cidr_blocks  = ["0.0.0.0/0"]
}


