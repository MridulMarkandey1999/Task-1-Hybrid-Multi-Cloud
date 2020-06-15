provider "aws" {
  region     = "ap-south-1"
  profile    = "myDemoUser"
}


resource "aws_security_group" "security_grp1" {
  name        = "allowing_http_from_port_80"

  ingress {
    description = "allowing http from port 80"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "allowing ssh from port 22"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_and_ssh"
  }
}

resource "aws_instance" "myinstance1" {
  ami           = "ami-0447a12f28fddb066"
  instance_type = "t2.micro"
  key_name      = "mykey1111.pem"
  security_groups = [ "${aws_security_group.security_grp1.name}" ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Mridul/Desktop/AWS/mykey1111.pem")
    host     = aws_instance.myinstance1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd php git -y",
      "sudo systemctl start httpd",
      "sudo systemctl enable httpd"
    ]
  }

  tags = {
    Name = "lwos1"
  }
}


resource "aws_ebs_volume" "ebs1" {
  availability_zone = aws_instance.myinstance1.availability_zone
  size              = 1

  tags = {
    Name = "myebs1"
  }
}

resource "aws_volume_attachment" "ebs_att" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.ebs1.id
  instance_id = aws_instance.myinstance1.id
  force_detach = true
}



output "my_os_ip" {
 value= aws_instance.myinstance1.public_ip
}


resource "null_resource" "nulllocal1" {

  provisioner "local-exec" {
      command = "echo ${aws_instance.myinstance1.public_ip} > publicip.txt"
    }
}

resource "null_resource" "nulllocal2" {

    depends_on = [
    null_resource.nulllocal3, aws_cloudfront_distribution.s3_distribution,
  ]

  provisioner "local-exec" {
     command = "chrome ${aws_instance.myinstance1.public_ip} "
   }
}



resource "null_resource" "nulllocal3" {

  depends_on = [
    aws_volume_attachment.ebs_att,
  ]

  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Mridul/Desktop/AWS/mykey1111.pem")
    host     = aws_instance.myinstance1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mkfs.ext4 /dev/xvdh",
      "sudo mount /dev/xvdh /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/MridulMarkandey1999/Multicloud.git /var/www/html/"
    ]
  }
}




resource "aws_s3_bucket" "task1_bucket" {
  bucket = "picbucket6787678"
  acl    = "public-read"

  tags = {
    Name        = "My Terraform bucket"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_object" "object" {

  depends_on = [
    aws_s3_bucket.task1_bucket,
  ]
  
  bucket = aws_s3_bucket.task1_bucket.bucket
  key    = "earth.jpg"
  source = "C:/Users/Mridul/Desktop/AWS/earth.jpg"
  acl  =  "public-read-write"
  content_type = "image/jpg"
}



variable "var1"{
	default=" S3-"
}


locals {
  s3_origin_id = "${var.var1}${aws_s3_bucket.task1_bucket.bucket}"
}

resource "aws_cloudfront_distribution" "s3_distribution" {

  depends_on = [
    aws_s3_bucket_object.object,
  ]

  origin {
    domain_name = aws_s3_bucket.task1_bucket.bucket_regional_domain_name
    origin_id   = "local.s3_origin_id"

    custom_origin_config {
      http_port = 80
      https_port = 80
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols=["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }

  enabled = true
    
  default_cache_behavior {
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "local.s3_origin_id"

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }

    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }


  viewer_certificate {
    cloudfront_default_certificate = true
  }


  connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/Mridul/Desktop/AWS/mykey1111.pem")
    host     = aws_instance.myinstance1.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo su << EOF",
      "echo \"<center><img src='http://${self.domain_name}/${aws_s3_bucket_object.object.key}' width ='450' height='300'></center>\" >> /var/www/html/index.php ",
      "EOF",
    ]
  }


}

