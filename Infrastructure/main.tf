resource "aws_dynamodb_table" "SampleTable" {
  name         = "SampleTable"
  billing_mode = "PROVISIONED"
  hash_key     = "userId"
  read_capacity  = 1
  write_capacity = 1

  attribute {
    name = "userId"
    type = "S"
  }

  tags = {
    Name        = "User"
    Environment = "development"
  }
}

# Adding Dummy data for testing Moto
resource "aws_dynamodb_table_item" "dummy_data_item1" {
  table_name = aws_dynamodb_table.SampleTable.name
  hash_key   = "userId"
  item = <<ITEM
{
  "userId": {"S": "user1"},
  "name": {"S": "Alice"},
  "email": {"S": "alice@example.com"}
}
ITEM
}

resource "aws_dynamodb_table_item" "dummy_data_item2" {
  table_name = aws_dynamodb_table.SampleTable.name
  hash_key   = "userId"
  item = <<ITEM
{
  "userId": {"S": "user2"},
  "name": {"S": "Bob"},
  "email": {"S": "bob@example.com"}
}
ITEM
}
