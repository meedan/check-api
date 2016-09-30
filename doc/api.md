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
  "error": "You need to sign in or sign up before continuing."
}
```

401: Access denied
```json
{
  "error": "You need to sign in or sign up before continuing."
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
  "error": "Invalid Email or password."
}
```

401: Could not sign in
```json
{
  "error": "Invalid Email or password."
}
```


#### DELETE /api/users/sign_out

Use this method in order to sign out

**Parameters**


**Response**

200: Signed out


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
  "type": "user",
  "data": {
    "id": "VXNlci8xNzk=\n",
    "dbid": 179,
    "name": "Test",
    "email": "t@test.com",
    "login": "t",
    "uuid": "checkdesk_44a0e02612a6a98445d56550038e20ae",
    "provider": "",
    "token": "eyJwcm92aWRlciI6ImNoZWNrZGVzayIsImlkIjoiIiwidG9rZW4iOiJtdEpO++nUm83TSIsInNlY3JldCI6IkdHd2JhTlZEIn0=++n",
    "current_team": null,
    "teams": "{}",
    "team_ids": [

    ],
    "permissions": "{}"
  }
}
```

400: Password is too short
```json
{
  "type": "error",
  "data": {
    "message": "Could not create user: Validation failed: Email has already been taken",
    "code": 4
  }
}
```

400: Passwords do not match
```json
{
  "type": "error",
  "data": {
    "message": "Could not create user: Validation failed: Email has already been taken",
    "code": 4
  }
}
```

400: E-mail missing
```json
{
  "type": "error",
  "data": {
    "message": "Could not create user: Validation failed: Email has already been taken",
    "code": 4
  }
}
```

400: Password is missing
```json
{
  "type": "error",
  "data": {
    "message": "Could not create user: Validation failed: Email has already been taken",
    "code": 4
  }
}
```

400: Name is missing
```json
{
  "type": "error",
  "data": {
    "message": "Could not create user: Validation failed: Email has already been taken",
    "code": 4
  }
}
```


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
  "error": "You need to sign in or sign up before continuing."
}
```

400: Password is too short
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

400: Passwords do not match
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

400: E-mail missing
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

400: Password is missing
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

400: Name is missing
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```


#### DELETE /api/users

Use this method in order to delete your account

**Parameters**


**Response**

200: Account deleted
```json
{
  "error": "You need to sign in or sign up before continuing."
}
```

