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
      "name": "Check",
      "version": "0.0.1"
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
  "error": "You have to confirm your email address before continuing."
}
```

401: Could not sign in
```json
{
  "error": "You have to confirm your email address before continuing."
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
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
    "code": 4
  }
}
```

400: Password is too short
```json
{
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
    "code": 4
  }
}
```

400: Passwords do not match
```json
{
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
    "code": 4
  }
}
```

400: E-mail missing
```json
{
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
    "code": 4
  }
}
```

400: Password is missing
```json
{
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
    "code": 4
  }
}
```

400: Name is missing
```json
{
  "type": "error",
  "data": {
    "message": "Validation failed: E-mail has already been taken",
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

