import { DynamoDBClient } from '@aws-sdk/client-dynamodb';
import { DynamoDBDocumentClient, GetCommand, PutCommand } from '@aws-sdk/lib-dynamodb';

const client = new DynamoDBClient({});
const dynamo = DynamoDBDocumentClient.from(client);
const tableName = process.env.DYNAMODB_TABLE;

export const handler = async (event, context) => {
  let body;

  switch (event.requestContext.http.method) {
    case 'POST':
      body = await dynamo.send(new GetCommand({
        TableName: tableName,
        Key: {
          Id: 'Count',
        },
      }));

      body.Item.Count = body.Item.Count + 1;

      await dynamo.send(new PutCommand({
        TableName: tableName,
        Item: {
          Id: 'Count',
          Count: body.Item.Count,
        },
      }));

      // The Id is not needed in the response.
      delete(body.Item.Id);

      return {
        statusCode: 201,
        body: JSON.stringify(body.Item),
      };
    case 'GET':
      body = await dynamo.send(new GetCommand({
        TableName: tableName,
        Key: {
          Id: 'Count',
        },
      }));

      if (!body.Item) {
        await dynamo.send(new PutCommand({
          TableName: tableName,
          Item: {
            Id: 'Count',
            Count: 0,
          },
        }));

        body = {Item: { Id: "Count", Count: 0 }};
      }

      // The Id is not needed in the response.
      delete(body.Item.Id);

      return {
        statusCode: 200,
        body: JSON.stringify(body.Item),
      };
    default:
      return {
        statusCode: 405,
        body: JSON.stringify({ message: 'Method Not Allowed' }),
      };
  }
};

