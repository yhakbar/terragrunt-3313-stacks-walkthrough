package main

import (
	"context"
	"math/rand"
	"strconv"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
)

func handleRequest(ctx context.Context, event events.LambdaFunctionURLRequest) (events.LambdaFunctionURLResponse, error) {
	randomNumber := rand.Intn(100)

	return events.LambdaFunctionURLResponse{
		StatusCode: 200,
		Body:       `{"count": ` + strconv.Itoa(randomNumber) + `}`,
	}, nil
}

func main() {
	lambda.Start(handleRequest)
}
