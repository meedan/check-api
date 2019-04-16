### API

#### GET /api/version

Use this method in order to get the current version of this application

**Parameters**


**Response**

200: The version of this application

401: Access denied


#### GET /api/me

Use this method in order to get information about current user, either by session or token

**Parameters**


**Response**

200: Information about current user, or nil if not authenticated


#### POST /api/graphql

Use this method in order to send queries to the GraphQL server

**Parameters**

* `query`: GraphQL query _(required)_

**Response**

200: GraphQL result

401: Access denied


#### POST /api/users/sign_in

Use this method in order to sign in

**Parameters**

* `api_user[email]`: E-mail _(required)_
* `api_user[password]`: Password _(required)_

**Response**

200: Signed in

401: Could not sign in


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

400: Password is too short

400: Passwords do not match

400: E-mail missing

400: Password is missing

400: Name is missing


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

400: Password is too short

400: Passwords do not match

400: E-mail missing

400: Password is missing

400: Name is missing


#### DELETE /api/users

Use this method in order to delete your account

**Parameters**


**Response**

200: Account deleted

