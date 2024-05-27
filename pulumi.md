## Tutorial: Implementação de uma Aplicação de Gestão de Tarefas usando Pulumi

### Pré-requisitos

1. **Conta AWS**: Você precisará de uma conta AWS. Se ainda não tiver uma, crie uma em [aws.amazon.com](https://aws.amazon.com).
2. **AWS CLI**: Instale a AWS Command Line Interface (CLI). Siga as instruções em [AWS CLI Installation](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html).
3. **Node.js**: Instale o Node.js (versão 12 ou superior). Baixe e instale a partir de [nodejs.org](https://nodejs.org/en/).
4. **Pulumi**: Instale o Pulumi. Siga as instruções em [Pulumi Installation](https://www.pulumi.com/docs/get-started/install/).
5. **Python**: Instale o Python (versão 3.7 ou superior). Baixe e instale a partir de [python.org](https://www.python.org/downloads/).

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

### Passo 2: Instalar e Configurar o Pulumi

Verifique se o Pulumi está instalado corretamente executando:

```sh
pulumi version
```

### Passo 3: Criar um Novo Projeto Pulumi

Crie um novo projeto Pulumi utilizando Python como a linguagem de programação:

```sh
pulumi new aws-python
```

Siga as instruções para configurar o projeto:

- Nome do Projeto: `todo-app`
- Descrição: `Application to manage tasks using Pulumi`
- Stack name: `dev`
- AWS Region: `us-east-1`

### Passo 4: Estrutura do Projeto

A estrutura do projeto será semelhante a esta:

```
todo-app
├── __main__.py
├── Pulumi.dev.yaml
├── Pulumi.yaml
├── requirements.txt
├── venv
└── __pycache__
```

### Passo 5: Definir a Infraestrutura no Pulumi

Abra o arquivo `__main__.py` e configure os recursos necessários:

```python
import pulumi
import pulumi_aws as aws

# DynamoDB Table
table = aws.dynamodb.Table('TodoTable',
    attributes=[{
        'name': 'id',
        'type': 'S'
    }],
    hash_key='id',
    billing_mode='PAY_PER_REQUEST')

# Lambda Role
role = aws.iam.Role('lambdaRole', assume_role_policy="""
{
    "Version": "2012-10-17",
    "Statement": [{
        "Action": "sts:AssumeRole",
        "Principal": {
            "Service": "lambda.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
    }]
}
""")

# Lambda Policy
policy = aws.iam.RolePolicy('lambdaPolicy', role=role.id, policy=table.arn.apply(lambda arn: f"""
{{
    "Version": "2012-10-17",
    "Statement": [
        {{
            "Effect": "Allow",
            "Action": [
                "dynamodb:*"
            ],
            "Resource": "{arn}"
        }},
        {{
            "Effect": "Allow",
            "Action": [
                "logs:*"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        }}
    ]
}}
"""))

# Lambda Functions
get_todos = aws.lambda_.Function('getTodosFunction',
    runtime='python3.8',
    role=role.arn,
    handler='handler.get_todos',
    code=pulumi.AssetArchive({
        '.': pulumi.FileArchive('./app')
    }),
    environment={
        'variables': {
            'TABLE_NAME': table.name,
        }
    })

create_todo = aws.lambda_.Function('createTodoFunction',
    runtime='python3.8',
    role=role.arn,
    handler='handler.create_todo',
    code=pulumi.AssetArchive({
        '.': pulumi.FileArchive('./app')
    }),
    environment={
        'variables': {
            'TABLE_NAME': table.name,
        }
    })

update_todo = aws.lambda_.Function('updateTodoFunction',
    runtime='python3.8',
    role=role.arn,
    handler='handler.update_todo',
    code=pulumi.AssetArchive({
        '.': pulumi.FileArchive('./app')
    }),
    environment={
        'variables': {
            'TABLE_NAME': table.name,
        }
    })

delete_todo = aws.lambda_.Function('deleteTodoFunction',
    runtime='python3.8',
    role=role.arn,
    handler='handler.delete_todo',
    code=pulumi.AssetArchive({
        '.': pulumi.FileArchive('./app')
    }),
    environment={
        'variables': {
            'TABLE_NAME': table.name,
        }
    })

# API Gateway
api = aws.apigateway.RestApi('todosApi', description='API for managing todos')

resource = aws.apigateway.Resource('todosResource',
    rest_api=api.id,
    parent_id=api.root_resource_id,
    path_part='todos')

resource_id = resource.id

methods = [
    {
        "function": get_todos,
        "method": "GET"
    },
    {
        "function": create_todo,
        "method": "POST"
    },
    {
        "function": update_todo,
        "method": "PUT"
    },
    {
        "function": delete_todo,
        "method": "DELETE"
    }
]

for method in methods:
    aws.apigateway.Method(f"{method['method'].lower()}Method",
        rest_api=api.id,
        resource_id=resource_id,
        http_method=method['method'],
        authorization='NONE',
        integration=aws.apigateway.Integration(
            type='AWS_PROXY',
            http_method='POST',
            uri=method['function'].invoke_arn,
            integration_http_method='POST',
        ))

# Deploy the API
deployment = aws.apigateway.Deployment('apiDeployment',
    rest_api=api.id,
    stage_name='dev')

pulumi.export('url', deployment.invoke_url.apply(lambda url: f"{url}todos"))
```

### Passo 6: Implementar as Funções Lambda

Crie um diretório `app` e dentro dele adicione o arquivo `handler.py` com o código das funções Lambda:

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

### Passo 7: Instalar Dependências

Crie um arquivo `requirements.txt` para listar as dependências do projeto:

```txt
boto3
```

Instale as dependências executando:

```sh
pip install -r requirements.txt

 -t ./app
```

### Passo 8: Implantar a Aplicação

Execute os comandos a seguir para inicializar e implantar a aplicação no Pulumi:

```sh
pulumi login
pulumi stack init dev
pulumi up
```

Confirme a implantação digitando `yes` quando solicitado.

### Passo 9: Testar a Aplicação

Após a implantação, você receberá o endpoint da API. Utilize ferramentas como Postman ou CURL para testar os endpoints `GET`, `POST`, `PUT` e `DELETE` da aplicação.

### Exemplo de Teste com CURL

**Criar uma Tarefa**:

```sh
curl -X POST https://<seu-endpoint>/todos -H "Content-Type: application/json" -d '{
  "id": "1",
  "title": "Comprar leite",
  "description": "Comprar leite no supermercado",
  "status": "pending"
}'
```

**Listar Tarefas**:

```sh
curl https://<seu-endpoint>/todos
```

**Atualizar uma Tarefa**:

```sh
curl -X PUT https://<seu-endpoint>/todos/1 -H "Content-Type: application/json" -d '{
  "title": "Comprar leite e pão",
  "status": "completed"
}'
```

**Deletar uma Tarefa**:

```sh
curl -X DELETE https://<seu-endpoint>/todos/1
```
