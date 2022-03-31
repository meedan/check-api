### API

#### GET /api/version

Use this method in order to get the current version of this application

**Parameters**


**Response**

200: The version of this application
```json
{
  "type": "version",
  "data": "Check v0.0.1"
}
```

401: Access denied
```json
{
  "errors": [
    {
      "message": "Unauthorized",
      "code": 1,
      "data": {
      }
    }
  ]
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
      "name": "Check",
      "version": "0.0.1"
    }
  },
  "extensions": {
    "tracing": {
      "version": 1,
      "startTime": "2022-03-31T21:23:19.903Z",
      "endTime": "2022-03-31T21:23:21.784Z",
      "duration": 1881003618,
      "execution": {
        "resolvers": [
          {
            "path": [
              "about"
            ],
            "parentType": "Query",
            "fieldName": "about",
            "returnType": "About",
            "startOffset": 1687765,
            "duration": 1878917217
          },
          {
            "path": [
              "about",
              "name"
            ],
            "parentType": "About",
            "fieldName": "name",
            "returnType": "String",
            "startOffset": 1880761623,
            "duration": 34570
          },
          {
            "path": [
              "about",
              "version"
            ],
            "parentType": "About",
            "fieldName": "version",
            "returnType": "String",
            "startOffset": 1880865573,
            "duration": 16212
          }
        ]
      }
    }
  }
}
```

401: Access denied
```json
{
  "data": {
    "about": {
      "name": "Check",
      "version": "0.0.1"
    }
  },
  "extensions": {
    "tracing": {
      "version": 1,
      "startTime": "2022-03-31T21:23:22.070Z",
      "endTime": "2022-03-31T21:23:22.100Z",
      "duration": 29601812,
      "execution": {
        "resolvers": [
          {
            "path": [
              "about"
            ],
            "parentType": "Query",
            "fieldName": "about",
            "returnType": "About",
            "startOffset": 985383,
            "duration": 28251647
          },
          {
            "path": [
              "about",
              "name"
            ],
            "parentType": "About",
            "fieldName": "name",
            "returnType": "String",
            "startOffset": 29363632,
            "duration": 46968
          },
          {
            "path": [
              "about",
              "version"
            ],
            "parentType": "About",
            "fieldName": "version",
            "returnType": "String",
            "startOffset": 29499530,
            "duration": 24080
          }
        ]
      }
    }
  }
}
```


#### POST /api/users/sign_in

Use this method in order to sign in

**Parameters**

* `api_user[email]`: E-mail _(required)_
* `api_user[password]`: Password _(required)_

**Response**

200: Signed in
```json
{
  "errors": [
    {
      "message": "Invalid Email or password.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

401: Could not sign in
```json
{
  "errors": [
    {
      "message": "Invalid Email or password.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```


#### DELETE /api/users/sign_out

Use this method in order to sign out

**Parameters**


**Response**

200: Signed out


#### PATCH /api/users

Use this method in order to update your account

**Parameters**

* `api_user[email]`: E-mail
* `api_user[name]`: Name
* `api_user[password]`: Password
* `api_user[password_confirmation]`: Password Confirmation
* `api_user[current_password]`: Current Password

**Response**

200: Account updated
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: Password is too short
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: Passwords do not match
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: E-mail missing
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: Password is missing
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: Name is missing
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```


#### DELETE /api/users

Use this method in order to delete your account

**Parameters**


**Response**

200: Account deleted
```json
{
  "errors": [
    {
      "message": "You need to sign in or sign up before continuing.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```


#### POST /api/users

Use this method in order to create a new user account

**Parameters**

* `api_user[email]`: E-mail _(required)_
* `api_user[name]`: Name _(required)_
* `api_user[password]`: Password _(required)_
* `api_user[password_confirmation]`: Password Confirmation _(required)_

**Response**

200: Account created
```json
{
  "errors": [
    {
      "message": "Please check your email to verify your account.",
      "code": 1,
      "data": {
      }
    }
  ]
}
```

400: Password is too short
```json
{
  "errors": [
    {
      "message": "Password is too short (minimum is 8 characters)",
      "code": 4,
      "data": {
      }
    }
  ]
}
```

400: Passwords do not match
```json
{
  "errors": [
    {
      "message": "Password confirmation doesn't match Password",
      "code": 4,
      "data": {
      }
    }
  ]
}
```

400: E-mail missing
```json
{
  "errors": [
    {
      "message": "Email can't be blank",
      "code": 4,
      "data": {
      }
    }
  ]
}
```

400: Password is missing
```json
{
  "errors": [
    {
      "message": "Password can't be blank",
      "code": 4,
      "data": {
      }
    }
  ]
}
```

400: Name is missing
```json
{
  "errors": [
    {
      "message": "Name can't be blank",
      "code": 4,
      "data": {
      }
    }
  ]
}
```

