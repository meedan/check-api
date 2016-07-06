### GraphQL

You can test the GraphQL endpoint by going to `/graphiql`. The available actions are:

#### Update Project Source

**Query**

```
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 2 }) { project_source { source_id } } }
```

**Result**

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "source_id": 2
      }
    }
  }
}
```

#### Read Project

**Query**

```
query read { root { projects { edges { node { title } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "title": "QBTCVMRYHA"
            }
          },
          {
            "node": {
              "title": "MWMUIQTSAB"
            }
          }
        ]
      }
    }
  }
}
```

#### Destroy Team

**Query**

```
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8x
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8x\n"
    }
  }
}
```

#### Read Media

**Query**

```
query read { root { medias { edges { node { url } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          },
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          }
        ]
      }
    }
  }
}
```

#### Update Team

**Query**

```
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8x
", name: "bar" }) { team { name } } }
```

**Result**

```json
{
  "data": {
    "updateTeam": {
      "team": {
        "name": "bar"
      }
    }
  }
}
```

#### Create Api Key

**Query**

```
mutation create { createApiKey(input: {application: "test", clientMutationId: "1"}) { api_key { id } } }
```

**Result**

```json
{
  "data": {
    "createApiKey": {
      "api_key": {
        "id": "QXBpS2V5LzE=\n"
      }
    }
  }
}
```

#### Read Object Project Source

**Query**

```
query read { root { project_sources { edges { node { project { title }, source { name } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "FHTAHUVYXZ"
              },
              "source": {
                "name": "RWQGTJWDGH"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "IBCZXHFESG"
              },
              "source": {
                "name": "QYNNJYDSLQ"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update Source

**Query**

```
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzI=
", name: "bar" }) { source { name } } }
```

**Result**

```json
{
  "data": {
    "updateSource": {
      "source": {
        "name": "bar"
      }
    }
  }
}
```

#### Read Api Key

**Query**

```
query read { root { api_keys { edges { node { application } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "api_keys": {
        "edges": [
          {
            "node": {
              "application": null
            }
          },
          {
            "node": {
              "application": null
            }
          }
        ]
      }
    }
  }
}
```

#### Update Media

**Query**

```
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 2 }) { media { user_id } } }
```

**Result**

```json
{
  "data": {
    "updateMedia": {
      "media": {
        "user_id": 2
      }
    }
  }
}
```

#### Read Object Account

**Query**

```
query read { root { accounts { edges { node { user { name }, source { name } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "AAIDBSQNDZ"
              },
              "source": {
                "name": "HYMNRUIDXJ"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "ADPWOULUZD"
              },
              "source": {
                "name": "QONKPXANDL"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Destroy Project

**Query**

```
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8x\n"
    }
  }
}
```

#### Read Comment

**Query**

```
query read { root { comments { edges { node { text } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "comments": {
        "edges": [
          {
            "node": {
              "text": "ORMBSGBBIJGIEOBFDYEXBGKOXXEHLPAKNVHSVUVSWHEOJEJOCF"
            }
          },
          {
            "node": {
              "text": "CGJYGEGZKYBNQYKUKCCJKUMETJSSOXDRTTQDIVWMMEOCMOOGEA"
            }
          }
        ]
      }
    }
  }
}
```

#### Update Project

**Query**

```
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
", title: "bar" }) { project { title } } }
```

**Result**

```json
{
  "data": {
    "updateProject": {
      "project": {
        "title": "bar"
      }
    }
  }
}
```

#### Destroy Account

**Query**

```
mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyAccount": {
      "deletedId": "QWNjb3VudC8x\n"
    }
  }
}
```

#### Read Collection Source

**Query**

```
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "ZDNSIXEFVQ"
                    }
                  },
                  {
                    "node": {
                      "title": "HQJIOHVDBM"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "https://www.youtube.com/user/MeedanTube"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 1
                    }
                  },
                  {
                    "node": {
                      "project_id": 2
                    }
                  }
                ]
              }
            }
          },
          {
            "node": {
              "projects": {
                "edges": [

                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "projects": {
                "edges": [

                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "projects": {
                "edges": [

                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "projects": {
                "edges": [

                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "projects": {
                "edges": [

                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Create Team User

**Query**

```
mutation create { createTeamUser(input: {team_id: 1, user_id: 1, clientMutationId: "1"}) { team_user { id } } }
```

**Result**

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvMQ==\n"
      }
    }
  }
}
```

#### Create Account

**Query**

```
mutation create { createAccount(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { account { id } } }
```

**Result**

```json
{
  "data": {
    "createAccount": {
      "account": {
        "id": "QWNjb3VudC8x\n"
      }
    }
  }
}
```

#### Destroy Team User

**Query**

```
mutation destroy { destroyTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyTeamUser": {
      "deletedId": "VGVhbVVzZXIvMQ==\n"
    }
  }
}
```

#### Create Media

**Query**

```
mutation create { createMedia(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { media { id } } }
```

**Result**

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvMQ==\n"
      }
    }
  }
}
```

#### Read Collection Account

**Query**

```
query read { root { accounts { edges { node { medias { edges { node { url } } } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "https://www.youtube.com/user/MeedanTube"
                    }
                  }
                ]
              }
            }
          },
          {
            "node": {
              "medias": {
                "edges": [

                ]
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Read Account

**Query**

```
query read { root { accounts { edges { node { url } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          },
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          }
        ]
      }
    }
  }
}
```

#### Create Team

**Query**

```
mutation create { createTeam(input: {name: "test", clientMutationId: "1"}) { team { id } } }
```

**Result**

```json
{
  "data": {
    "createTeam": {
      "team": {
        "id": "VGVhbS8x\n"
      }
    }
  }
}
```

#### Destroy Project Source

**Query**

```
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8x\n"
    }
  }
}
```

#### Destroy Comment

**Query**

```
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlc5c1pOZnQ3a2dpSVY3Y19zYw==
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVlc5c1pOZnQ3a2dpSVY3Y19zYw==\n"
    }
  }
}
```

#### Update Comment

**Query**

```
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlc5c1p1SXQ3a2dpSVY3Y19zZA==
", text: "bar" }) { comment { text } } }
```

**Result**

```json
{
  "data": {
    "updateComment": {
      "comment": {
        "text": "bar"
      }
    }
  }
}
```

#### Read Collection Team

**Query**

```
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "team_users": {
                "edges": [
                  {
                    "node": {
                      "user_id": 2
                    }
                  },
                  {
                    "node": {
                      "user_id": 3
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "UAKEVBWSDK"
                    }
                  },
                  {
                    "node": {
                      "name": "BKDRQZJARH"
                    }
                  }
                ]
              }
            }
          },
          {
            "node": {
              "team_users": {
                "edges": [

                ]
              },
              "users": {
                "edges": [

                ]
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Read Object Team User

**Query**

```
query read { root { team_users { edges { node { team { name }, user { name } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "OGHPXKFSFX"
              },
              "user": {
                "name": "MXDUFOCDDX"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "TNSSDSXNTD"
              },
              "user": {
                "name": "ATCIHNKBKW"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Read Object Project

**Query**

```
query read { root { projects { edges { node { user { name } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "HUHHRYRNLS"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "QYRTEGPMBF"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update Account

**Query**

```
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 2 }) { account { user_id } } }
```

**Result**

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 2
      }
    }
  }
}
```

#### Create Comment

**Query**

```
mutation create { createComment(input: {text: "test", clientMutationId: "1"}) { comment { id } } }
```

**Result**

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVlc5c2FYMXQ3a2dpSVY3Y19zZQ==\n"
      }
    }
  }
}
```

#### Destroy User

**Query**

```
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8y
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8y\n"
    }
  }
}
```

#### Update Team User

**Query**

```
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
", team_id: 2 }) { team_user { team_id } } }
```

**Result**

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 2
      }
    }
  }
}
```

#### Destroy Media

**Query**

```
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMQ==\n"
    }
  }
}
```

#### Create Source

**Query**

```
mutation create { createSource(input: {name: "test", clientMutationId: "1"}) { source { id } } }
```

**Result**

```json
{
  "data": {
    "createSource": {
      "source": {
        "id": "U291cmNlLzI=\n"
      }
    }
  }
}
```

#### Read Project Source

**Query**

```
query read { root { project_sources { edges { node { source_id } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "source_id": 3
            }
          },
          {
            "node": {
              "source_id": 5
            }
          }
        ]
      }
    }
  }
}
```

#### Read Team User

**Query**

```
query read { root { team_users { edges { node { user_id } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "user_id": 2
            }
          },
          {
            "node": {
              "user_id": 3
            }
          }
        ]
      }
    }
  }
}
```

#### Create Project

**Query**

```
mutation create { createProject(input: {title: "test", clientMutationId: "1"}) { project { id } } }
```

**Result**

```json
{
  "data": {
    "createProject": {
      "project": {
        "id": "UHJvamVjdC8x\n"
      }
    }
  }
}
```

#### Read User

**Query**

```
query read { root { users { edges { node { email } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "users": {
        "edges": [
          {
            "node": {
              "email": "niyhshqwsz@oimxvpzlui.com"
            }
          },
          {
            "node": {
              "email": "fyezdltpdw@peufmmvyqh.com"
            }
          }
        ]
      }
    }
  }
}
```

#### Destroy Api Key

**Query**

```
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzE=\n"
    }
  }
}
```

#### Update Api Key

**Query**

```
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
", application: "bar" }) { api_key { application } } }
```

**Result**

```json
{
  "data": {
    "updateApiKey": {
      "api_key": {
        "application": "bar"
      }
    }
  }
}
```

#### Create User

**Query**

```
mutation create { createUser(input: {email: "user@test.test", login: "test", name: "Test", password: "12345678", password_confirmation: "12345678", clientMutationId: "1"}) { user { id } } }
```

**Result**

```json
{
  "data": {
    "createUser": {
      "user": {
        "id": "VXNlci8y\n"
      }
    }
  }
}
```

#### Read Object Media

**Query**

```
query read { root { medias { edges { node { project { title }, account { url }, user { name } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "NMVKVOWNBD"
              },
              "account": {
                "url": "https://www.youtube.com/user/MeedanTube"
              },
              "user": {
                "name": "SXVWEPVBAH"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "JCUPXGDLUL"
              },
              "account": {
                "url": "https://www.youtube.com/user/MeedanTube"
              },
              "user": {
                "name": "TJZEDIVCQC"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update User

**Query**

```
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8y
", name: "Bar" }) { user { name } } }
```

**Result**

```json
{
  "data": {
    "updateUser": {
      "user": {
        "name": "Bar"
      }
    }
  }
}
```

#### Read Source

**Query**

```
query read { root { sources { edges { node { name } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "name": "FFBQPANIWD"
            }
          },
          {
            "node": {
              "name": "LDQSUHSSCS"
            }
          }
        ]
      }
    }
  }
}
```

#### Read Team

**Query**

```
query read { root { teams { edges { node { name } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "name": "PRLWCAFLPZ"
            }
          },
          {
            "node": {
              "name": "RJUOQNNDVN"
            }
          }
        ]
      }
    }
  }
}
```

#### Destroy Source

**Query**

```
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzI=
" }) { deletedId } }
```

**Result**

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzI=\n"
    }
  }
}
```

#### Create Project Source

**Query**

```
mutation create { createProjectSource(input: {source_id: 1, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
```

**Result**

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS8x\n"
      }
    }
  }
}
```

#### Read Collection Project

**Query**

```
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

**Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "sources": {
                "edges": [
                  {
                    "node": {
                      "name": "ETPIAHMQKL"
                    }
                  },
                  {
                    "node": {
                      "name": "MBNEYJNFNN"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "https://www.youtube.com/user/MeedanTube"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 1
                    }
                  },
                  {
                    "node": {
                      "project_id": 1
                    }
                  }
                ]
              }
            }
          },
          {
            "node": {
              "sources": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "sources": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [

                ]
              }
            }
          }
        ]
      }
    }
  }
}
```

