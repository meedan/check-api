# GraphQL Documentation

You can test the GraphQL endpoint by going to `/graphiql`. The available actions are:

## Create Team

### **Query**

```graphql
mutation create { createTeam(input: {name: "test", description: "test", clientMutationId: "1"}) { team { id } } }
```

### **Result**

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

## Destroy Project

### **Query**

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8x\n"
    }
  }
}
```

## Create Source

### **Query**

```graphql
mutation create { createSource(input: {name: "test", slogan: "test", clientMutationId: "1"}) { source { id } } }
```

### **Result**

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

## Destroy Comment

### **Query**

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUWDNjbTVjcG1wUlhNQXg3WQ==
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVllUWDNjbTVjcG1wUlhNQXg3WQ==\n"
    }
  }
}
```

## Update Team

### **Query**

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8x
", name: "bar" }) { team { name } } }
```

### **Result**

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

## Create Api Key

### **Query**

```graphql
mutation create { createApiKey(input: {application: "test", clientMutationId: "1"}) { api_key { id } } }
```

### **Result**

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

## Read Api Key

### **Query**

```graphql
query read { root { api_keys { edges { node { application } } } } }
```

### **Result**

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

## Read Media

### **Query**

```graphql
query read { root { medias { edges { node { url } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "url": "http://AKOOQHIOBU.com"
            }
          },
          {
            "node": {
              "url": "http://YCFIQZQSJU.com"
            }
          }
        ]
      }
    }
  }
}
```

## Create Project Source

### **Query**

```graphql
mutation create { createProjectSource(input: {source_id: 1, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
```

### **Result**

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

## Read Collection Account

### **Query**

```graphql
query read { root { accounts { edges { node { medias { edges { node { url } } } } } } } }
```

### **Result**

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
                      "url": "http://NPRCUWWWNH.com"
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

## Update User

### **Query**

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8y
", name: "Bar" }) { user { name } } }
```

### **Result**

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

## Read Team User

### **Query**

```graphql
query read { root { team_users { edges { node { user_id } } } } }
```

### **Result**

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

## Read Team

### **Query**

```graphql
query read { root { teams { edges { node { name } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "name": "OBURVKFTBP"
            }
          },
          {
            "node": {
              "name": "GQMVCRZXGG"
            }
          }
        ]
      }
    }
  }
}
```

## Destroy Team User

### **Query**

```graphql
mutation destroy { destroyTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyTeamUser": {
      "deletedId": "VGVhbVVzZXIvMQ==\n"
    }
  }
}
```

## Read Collection Project

### **Query**

```graphql
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

### **Result**

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
                      "name": "ZDPDZETLCK"
                    }
                  },
                  {
                    "node": {
                      "name": "STPFSPVCGB"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://GGGGSRITKE.com"
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
          }
        ]
      }
    }
  }
}
```

## Update Media

### **Query**

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 2 }) { media { user_id } } }
```

### **Result**

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

## Read Project Source

### **Query**

```graphql
query read { root { project_sources { edges { node { source_id } } } } }
```

### **Result**

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

## Create Media

### **Query**

```graphql
mutation create { createMedia(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { media { id } } }
```

### **Result**

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

## Read Collection Source

### **Query**

```graphql
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

### **Result**

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
                      "title": "JYVWEIOHJC"
                    }
                  },
                  {
                    "node": {
                      "title": "KVHIWKXTNZ"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://BZHXTBEXIG.com"
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

## Read Comment

### **Query**

```graphql
query read { root { comments { edges { node { text } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "comments": {
        "edges": [
          {
            "node": {
              "text": "CLSINJDUGWBZCCVHCPRLDTOAYYXXZRNSFLNMOWNAERFQDYDKNL"
            }
          },
          {
            "node": {
              "text": "USSVOZUIVCSLKHRAHLIIDCUZWSTCIOJGCQZTZXGVWMBCPVMRWL"
            }
          }
        ]
      }
    }
  }
}
```

## Create Team User

### **Query**

```graphql
mutation create { createTeamUser(input: {team_id: 1, user_id: 1, clientMutationId: "1"}) { team_user { id } } }
```

### **Result**

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

## Destroy Account

### **Query**

```graphql
mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyAccount": {
      "deletedId": "QWNjb3VudC8x\n"
    }
  }
}
```

## Read Object Team User

### **Query**

```graphql
query read { root { team_users { edges { node { team { name }, user { name } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "BNGHIOPUEF"
              },
              "user": {
                "name": "CSRYHYTDAW"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "GHTZPITYKY"
              },
              "user": {
                "name": "KRNRJUMAEE"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Update Project Source

### **Query**

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 2 }) { project_source { source_id } } }
```

### **Result**

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

## Destroy Media

### **Query**

```graphql
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMQ==\n"
    }
  }
}
```

## Read Object Account

### **Query**

```graphql
query read { root { accounts { edges { node { user { name }, source { name } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "QKKQFIIOSH"
              },
              "source": {
                "name": "FRKFUUBZXF"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "QBQTEGBSNE"
              },
              "source": {
                "name": "CDMSQWQJMA"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Read Source

### **Query**

```graphql
query read { root { sources { edges { node { name } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "name": "PFKQQIQDZD"
            }
          },
          {
            "node": {
              "name": "XWZMGEZAJU"
            }
          }
        ]
      }
    }
  }
}
```

## Update Project

### **Query**

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
", title: "bar" }) { project { title } } }
```

### **Result**

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

## Read Object Project

### **Query**

```graphql
query read { root { projects { edges { node { user { name } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "KYCNEKHNXR"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "ULMQJKZLRY"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Read Collection Team

### **Query**

```graphql
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } } } } } } }
```

### **Result**

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
                      "name": "NODBFASXET"
                    }
                  },
                  {
                    "node": {
                      "name": "OBPHRDEZAF"
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

## Read Project

### **Query**

```graphql
query read { root { projects { edges { node { title } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "title": "EIGRFPNBUA"
            }
          },
          {
            "node": {
              "title": "GKMSGTYQIU"
            }
          }
        ]
      }
    }
  }
}
```

## Create Project

### **Query**

```graphql
mutation create { createProject(input: {title: "test", description: "test", clientMutationId: "1"}) { project { id } } }
```

### **Result**

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

## Destroy Api Key

### **Query**

```graphql
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzE=\n"
    }
  }
}
```

## Update Comment

### **Query**

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUWDUwRTVjcG1wUlhNQXg3Yg==
", text: "bar" }) { comment { text } } }
```

### **Result**

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

## Read Collection Media

### **Query**

```graphql
query read { root { medias { edges { node { projects { edges { node { title } } } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "RDYHTTZAZS"
                    }
                  }
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

## Update Team User

### **Query**

```graphql
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
", team_id: 2 }) { team_user { team_id } } }
```

### **Result**

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

## Destroy Source

### **Query**

```graphql
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzI=
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzI=\n"
    }
  }
}
```

## Read Object Project Source

### **Query**

```graphql
query read { root { project_sources { edges { node { project { title }, source { name } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "YQKWGSHBWV"
              },
              "source": {
                "name": "IJLMWRMGWL"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "FIAOUSEGGI"
              },
              "source": {
                "name": "ZIYEDUSMGT"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Create User

### **Query**

```graphql
mutation create { createUser(input: {email: "user@test.test", login: "test", name: "Test", password: "12345678", password_confirmation: "12345678", clientMutationId: "1"}) { user { id } } }
```

### **Result**

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

## Update Account

### **Query**

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 2 }) { account { user_id } } }
```

### **Result**

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

## Destroy Project Source

### **Query**

```graphql
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8x\n"
    }
  }
}
```

## Read Account

### **Query**

```graphql
query read { root { accounts { edges { node { url } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "url": "http://HZHDLRYUGN.com"
            }
          },
          {
            "node": {
              "url": "http://WZGREWTPAL.com"
            }
          }
        ]
      }
    }
  }
}
```

## Create Comment

### **Query**

```graphql
mutation create { createComment(input: {text: "test", clientMutationId: "1"}) { comment { id } } }
```

### **Result**

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVllUWDZrYzVjcG1wUlhNQXg3Yw==\n"
      }
    }
  }
}
```

## Read User

### **Query**

```graphql
query read { root { users { edges { node { email } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "users": {
        "edges": [
          {
            "node": {
              "email": "bolhfrfewb@ypllukxtss.com"
            }
          },
          {
            "node": {
              "email": "rbkpcygleb@vctlitgryb.com"
            }
          }
        ]
      }
    }
  }
}
```

## Read Object Media

### **Query**

```graphql
query read { root { medias { edges { node { account { url }, user { name } } } } } }
```

### **Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "account": {
                "url": "http://MZVTPEOODE.com"
              },
              "user": {
                "name": "BFRLHJCRZY"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://AFJLTXVPSP.com"
              },
              "user": {
                "name": "OUCMEJPFLE"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Destroy User

### **Query**

```graphql
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8y
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8y\n"
    }
  }
}
```

## Update Api Key

### **Query**

```graphql
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
", application: "bar" }) { api_key { application } } }
```

### **Result**

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

## Destroy Team

### **Query**

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8x
" }) { deletedId } }
```

### **Result**

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8x\n"
    }
  }
}
```

## Update Source

### **Query**

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzI=
", name: "bar" }) { source { name } } }
```

### **Result**

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

## Create Account

### **Query**

```graphql
mutation create { createAccount(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { account { id } } }
```

### **Result**

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

