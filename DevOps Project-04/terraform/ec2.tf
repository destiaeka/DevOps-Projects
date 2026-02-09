resource "aws_instance" "ansible-controller" {
  ami                    = "ami-0b6c6ebed2801a5cb"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app-pub-a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = "deployment"

  tags = {
    Name = "ansible-controller"
  }
}

resource "aws_instance" "jenkins-master" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app-pub-a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = "deployment"

  tags = {
    Name = "jenkins-master"
  }
}

resource "aws_instance" "jenkins-agent" {
  ami                    = "ami-053b0d53c279acc90"
  instance_type          = "t3.small"
  subnet_id              = aws_subnet.app-pub-a.id
  vpc_security_group_ids = [aws_security_group.app.id]
  key_name               = "deployment"

  tags = {
    Name = "jenkins-agent"
  }
}