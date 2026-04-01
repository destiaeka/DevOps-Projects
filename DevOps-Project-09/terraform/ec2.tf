resource "aws_instance" "crud_testing_ec2" {
  ami                    = "ami-0c3389a4fa5bddaad"
  instance_type          = "t2.large"
  subnet_id              = aws_subnet.pub_a.id
  vpc_security_group_ids = [aws_security_group.sg_global.id]
  key_name               = "aws"
  user_data              = ("${path.module}/script.sh")

  tags = {
    Name = "crud_testing_ec2"
  }
}