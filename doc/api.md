### API

#### GET /api/version

Use this method in order to get the current version of this application

**Parameters**


**Response**

200: The version of this application
```json
{
  "type": "version",
  "data": "Checkdesk v0.0.1"
}
```

401: Access denied
```json
{
  "type": "error",
  "data": {
    "message": "Unauthorized",
    "code": 1
  }
}
```


#### GET /api/me

Use this method in order to get information about current user, either by session or token

**Parameters**


**Response**

200: Information about current user, or nil if not authenticated
```json
{
  "type": "user"
}
```


#### POST /api/graphql

Use this method in order to send queries to the GraphQL server

**Parameters**

* `query`: GraphQL query _(required)_

**Response**

200: GraphQL result
```json
{
  "data": {
    "about": {
      "name": "Checkdesk",
      "version": "0.0.1"
    }
  }
}
```

401: Access denied
```json
{
  "type": "error",
  "data": {
    "message": "Unauthorized",
    "code": 1
  }
}
```

