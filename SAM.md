## Tutorial: Implementação de uma Aplicação de Gestão de Tarefas usando AWS SAM

### Pré-requisitos

1. **Conta AWS**: Você precisará de uma conta AWS. Se ainda não tiver uma, crie uma em [aws.amazon.com](https://aws.amazon.com).
2. **AWS CLI**: Instale a AWS Command Line Interface (CLI). Siga as instruções em [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
3. **AWS SAM CLI**: Instale a AWS SAM CLI. Siga as instruções em [AWS SAM CLI Installation](https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/serverless-sam-cli-install.html).
4. **Python**: Instale o Python (versão 3.7 ou superior). Baixe e instale a partir de [python.org](https://www.python.org/downloads/).

### Passo 1: Configurar a AWS CLI

Configure a AWS CLI com suas credenciais. Execute o comando abaixo no terminal:

```sh
aws configure
```

Forneça suas credenciais da AWS, região padrão e formato de saída:

- **AWS Access Key ID**: Sua chave de acesso.
- **AWS Secret Access Key**: Sua chave secreta.
- **Default region name**: A região AWS que deseja usar (ex: `us-east-1`).
- **Default output format**: Formato de saída, pode ser `json`.

### Passo 2: Instalar o AWS SAM CLI

Verifique se o AWS SAM CLI está instalado corretamente executando:

```sh
sam --version
```

### Passo 3: Criar um Novo Projeto SAM

Crie uma nova aplicação SAM utilizando um modelo de exemplo:

```sh
sam init
```

Selecione as opções a seguir:
- Escolha 1: "AWS Quick Start Templates"
- Escolha 1: "Python 3.x"
- Nome do Projeto: "todo-app"

### Passo 4: Estrutura do Projeto

Após a inicialização, a estrutura do projeto será semelhante a esta:

```
todo-app
├── README.md
├── events
│   └── event.json
├── hello_world
│   ├── __init__.py
│   ├── app.py
│   ├── requirements.txt
├── template.yaml
└── tests
    ├── __init__.py
    └── unit
        ├── __init__.py
        └── test_handler.py
```

### Passo 5: Definir o Modelo SAM (template.yaml)

Abra o arquivo `template.yaml` e defina os recursos necessários para a aplicação de gestão de tarefas:

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Transform: 'AWS::Serverless-2016-10-31'
Description: >
  todo-app

Resources:
  TodoTable:
    Type: AWS::DynamoDB::Table
    Properties:
      TableName: TodoTable
      AttributeDefinitions:
        - AttributeName: id
          AttributeType: S
      KeySchema:
        - AttributeName: id
          KeyType: HASH
      BillingMode: PAY_PER_REQUEST

  GetTodosFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hello_world.get_todos
      Runtime: python3.8
      CodeUri: hello_world/
      Environment:
        Variables:
          TABLE_NAME: !Ref TodoTable
      Events:
        Api:
          Type: Api
          Properties:
            Path: /todos
            Method: get

  CreateTodoFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hello_world.create_todo
      Runtime: python3.8
      CodeUri: hello_world/
      Environment:
        Variables:
          TABLE_NAME: !Ref TodoTable
      Events:
        Api:
          Type: Api
          Properties:
            Path: /todos
            Method: post

  UpdateTodoFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hello_world.update_todo
      Runtime: python3.8
      CodeUri: hello_world/
      Environment:
        Variables:
          TABLE_NAME: !Ref TodoTable
      Events:
        Api:
          Type: Api
          Properties:
            Path: /todos/{id}
            Method: put

  DeleteTodoFunction:
    Type: AWS::Serverless::Function
    Properties:
      Handler: hello_world.delete_todo
      Runtime: python3.8
      CodeUri: hello_world/
      Environment:
        Variables:
          TABLE_NAME: !Ref TodoTable
      Events:
        Api:
          Type: Api
          Properties:
            Path: /todos/{id}
            Method: delete
```

### Passo 6: Implementar as Funções Lambda

Abra o arquivo `hello_world/app.py` e adicione o código para as funções Lambda:

```python
import json
import boto3
import os
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table(os.environ['TABLE_NAME'])

def get_todos(event, context):
    result = table.scan()
    return {
        'statusCode': 200,
        'body': json.dumps(result['Items'])
    }

def create_todo(event, context):
    data = json.loads(event['body'])
    if 'id' not in data or 'title' not in data:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Bad request'})
        }
    item = {
        'id': data['id'],
        'title': data['title'],
        'description': data.get('description', ''),
        'status': data.get('status', 'pending')
    }
    table.put_item(Item=item)
    return {
        'statusCode': 201,
        'body': json.dumps(item)
    }

def update_todo(event, context):
    todo_id = event['pathParameters']['id']
    data = json.loads(event['body'])
    if 'title' not in data and 'description' not in data and 'status' not in data:
        return {
            'statusCode': 400,
            'body': json.dumps({'error': 'Bad request'})
        }
    update_expression = "SET "
    expression_attribute_values = {}
    if 'title' in data:
        update_expression += "title = :title, "
        expression_attribute_values[':title'] = data['title']
    if 'description' in data:
        update_expression += "description = :description, "
        expression_attribute_values[':description'] = data['description']
    if 'status' in data:
        update_expression += "status = :status, "
        expression_attribute_values[':status'] = data['status']
    update_expression = update_expression.rstrip(", ")

    result = table.update_item(
        Key={'id': todo_id},
        UpdateExpression=update_expression,
        ExpressionAttributeValues=expression_attribute_values,
        ReturnValues="ALL_NEW"
    )
    return {
        'statusCode': 200,
        'body': json.dumps(result['Attributes'])
    }

def delete_todo(event, context):
    todo_id = event['pathParameters']['id']
    table.delete_item(Key={'id': todo_id})
    return {
        'statusCode': 204
    }
```

### Passo 7: Implantar a Aplicação

Antes de implantar, crie um bucket S3 para armazenar o código da função Lambda:

```sh
aws s3 mb s3://<seu-bucket-sam>
```

Substitua `<seu-bucket-sam>` pelo nome do bucket que deseja criar.

Agora, empacote e implante a aplicação:

```sh
sam package --output-template-file packaged.yaml --s3-bucket <seu-bucket-sam>
sam deploy --template-file packaged.yaml --stack-name todo-app --capabilities CAPABILITY_IAM
```

### Passo 8: Testar a Aplicação

Após a implantação, você receberá o endpoint da API. Utilize ferramentas como Postman ou CURL para testar os endpoints `GET`, `POST`, `PUT` e `DELETE` da aplicação.
