# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

    * [Account](#account)
      * [<strong>Update Account</strong>](#update-account)
        * [<strong>Query</strong>](#query)
        * [<strong>Result</strong>](#result)
      * [<strong>Destroy Account</strong>](#destroy-account)
        * [<strong>Query</strong>](#query-1)
        * [<strong>Result</strong>](#result-1)
      * [<strong>Read Object Account</strong>](#read-object-account)
        * [<strong>Query</strong>](#query-2)
        * [<strong>Result</strong>](#result-2)
      * [<strong>Read Account</strong>](#read-account)
        * [<strong>Query</strong>](#query-3)
        * [<strong>Result</strong>](#result-3)
      * [<strong>Create Account</strong>](#create-account)
        * [<strong>Query</strong>](#query-4)
        * [<strong>Result</strong>](#result-4)
      * [<strong>Read Collection Account</strong>](#read-collection-account)
        * [<strong>Query</strong>](#query-5)
        * [<strong>Result</strong>](#result-5)
    * [Api Key](#api-key)
      * [<strong>Update Api Key</strong>](#update-api-key)
        * [<strong>Query</strong>](#query-6)
        * [<strong>Result</strong>](#result-6)
      * [<strong>Read Api Key</strong>](#read-api-key)
        * [<strong>Query</strong>](#query-7)
        * [<strong>Result</strong>](#result-7)
      * [<strong>Create Api Key</strong>](#create-api-key)
        * [<strong>Query</strong>](#query-8)
        * [<strong>Result</strong>](#result-8)
      * [<strong>Destroy Api Key</strong>](#destroy-api-key)
        * [<strong>Query</strong>](#query-9)
        * [<strong>Result</strong>](#result-9)
    * [Comment](#comment)
      * [<strong>Create Comment</strong>](#create-comment)
        * [<strong>Query</strong>](#query-10)
        * [<strong>Result</strong>](#result-10)
      * [<strong>Destroy Comment</strong>](#destroy-comment)
        * [<strong>Query</strong>](#query-11)
        * [<strong>Result</strong>](#result-11)
      * [<strong>Update Comment</strong>](#update-comment)
        * [<strong>Query</strong>](#query-12)
        * [<strong>Result</strong>](#result-12)
      * [<strong>Read Comment</strong>](#read-comment)
        * [<strong>Query</strong>](#query-13)
        * [<strong>Result</strong>](#result-13)
    * [Media](#media)
      * [<strong>Read Object Media</strong>](#read-object-media)
        * [<strong>Query</strong>](#query-14)
        * [<strong>Result</strong>](#result-14)
      * [<strong>Read Media</strong>](#read-media)
        * [<strong>Query</strong>](#query-15)
        * [<strong>Result</strong>](#result-15)
      * [<strong>Destroy Media</strong>](#destroy-media)
        * [<strong>Query</strong>](#query-16)
        * [<strong>Result</strong>](#result-16)
      * [<strong>Read Collection Media</strong>](#read-collection-media)
        * [<strong>Query</strong>](#query-17)
        * [<strong>Result</strong>](#result-17)
      * [<strong>Update Media</strong>](#update-media)
        * [<strong>Query</strong>](#query-18)
        * [<strong>Result</strong>](#result-18)
      * [<strong>Create Media</strong>](#create-media)
        * [<strong>Query</strong>](#query-19)
        * [<strong>Result</strong>](#result-19)
    * [Project](#project)
      * [<strong>Read Object Project</strong>](#read-object-project)
        * [<strong>Query</strong>](#query-20)
        * [<strong>Result</strong>](#result-20)
      * [<strong>Destroy Project</strong>](#destroy-project)
        * [<strong>Query</strong>](#query-21)
        * [<strong>Result</strong>](#result-21)
      * [<strong>Update Project</strong>](#update-project)
        * [<strong>Query</strong>](#query-22)
        * [<strong>Result</strong>](#result-22)
      * [<strong>Create Project</strong>](#create-project)
        * [<strong>Query</strong>](#query-23)
        * [<strong>Result</strong>](#result-23)
      * [<strong>Read Project</strong>](#read-project)
        * [<strong>Query</strong>](#query-24)
        * [<strong>Result</strong>](#result-24)
      * [<strong>Read Collection Project</strong>](#read-collection-project)
        * [<strong>Query</strong>](#query-25)
        * [<strong>Result</strong>](#result-25)
    * [Project Source](#project-source)
      * [<strong>Update Project Source</strong>](#update-project-source)
        * [<strong>Query</strong>](#query-26)
        * [<strong>Result</strong>](#result-26)
      * [<strong>Create Project Source</strong>](#create-project-source)
        * [<strong>Query</strong>](#query-27)
        * [<strong>Result</strong>](#result-27)
      * [<strong>Read Project Source</strong>](#read-project-source)
        * [<strong>Query</strong>](#query-28)
        * [<strong>Result</strong>](#result-28)
      * [<strong>Read Object Project Source</strong>](#read-object-project-source)
        * [<strong>Query</strong>](#query-29)
        * [<strong>Result</strong>](#result-29)
      * [<strong>Destroy Project Source</strong>](#destroy-project-source)
        * [<strong>Query</strong>](#query-30)
        * [<strong>Result</strong>](#result-30)
    * [Source](#source)
      * [<strong>Create Source</strong>](#create-source)
        * [<strong>Query</strong>](#query-31)
        * [<strong>Result</strong>](#result-31)
      * [<strong>Read Source</strong>](#read-source)
        * [<strong>Query</strong>](#query-32)
        * [<strong>Result</strong>](#result-32)
      * [<strong>Destroy Source</strong>](#destroy-source)
        * [<strong>Query</strong>](#query-33)
        * [<strong>Result</strong>](#result-33)
      * [<strong>Update Source</strong>](#update-source)
        * [<strong>Query</strong>](#query-34)
        * [<strong>Result</strong>](#result-34)
      * [<strong>Read Collection Source</strong>](#read-collection-source)
        * [<strong>Query</strong>](#query-35)
        * [<strong>Result</strong>](#result-35)
    * [Team](#team)
      * [<strong>Create Team</strong>](#create-team)
        * [<strong>Query</strong>](#query-36)
        * [<strong>Result</strong>](#result-36)
      * [<strong>Destroy Team</strong>](#destroy-team)
        * [<strong>Query</strong>](#query-37)
        * [<strong>Result</strong>](#result-37)
      * [<strong>Read Team</strong>](#read-team)
        * [<strong>Query</strong>](#query-38)
        * [<strong>Result</strong>](#result-38)
      * [<strong>Update Team</strong>](#update-team)
        * [<strong>Query</strong>](#query-39)
        * [<strong>Result</strong>](#result-39)
      * [<strong>Read Collection Team</strong>](#read-collection-team)
        * [<strong>Query</strong>](#query-40)
        * [<strong>Result</strong>](#result-40)
    * [Team User](#team-user)
      * [<strong>Destroy Team User</strong>](#destroy-team-user)
        * [<strong>Query</strong>](#query-41)
        * [<strong>Result</strong>](#result-41)
      * [<strong>Update Team User</strong>](#update-team-user)
        * [<strong>Query</strong>](#query-42)
        * [<strong>Result</strong>](#result-42)
      * [<strong>Read Team User</strong>](#read-team-user)
        * [<strong>Query</strong>](#query-43)
        * [<strong>Result</strong>](#result-43)
      * [<strong>Read Object Team User</strong>](#read-object-team-user)
        * [<strong>Query</strong>](#query-44)
        * [<strong>Result</strong>](#result-44)
      * [<strong>Create Team User</strong>](#create-team-user)
        * [<strong>Query</strong>](#query-45)
        * [<strong>Result</strong>](#result-45)
    * [User](#user)
      * [<strong>Read User</strong>](#read-user)
        * [<strong>Query</strong>](#query-46)
        * [<strong>Result</strong>](#result-46)
      * [<strong>Destroy User</strong>](#destroy-user)
        * [<strong>Query</strong>](#query-47)
        * [<strong>Result</strong>](#result-47)
      * [<strong>Update User</strong>](#update-user)
        * [<strong>Query</strong>](#query-48)
        * [<strong>Result</strong>](#result-48)
      * [<strong>Create User</strong>](#create-user)
        * [<strong>Query</strong>](#query-49)
        * [<strong>Result</strong>](#result-49)
## Account
### __Update Account__

#### __Query__

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 2 }) { account { user_id } } }
```

#### __Result__

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

### __Destroy Account__

#### __Query__

```graphql
mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyAccount": {
      "deletedId": "QWNjb3VudC8x\n"
    }
  }
}
```

### __Read Object Account__

#### __Query__

```graphql
query read { root { accounts { edges { node { user { name }, source { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "BUHOOOCYSD"
              },
              "source": {
                "name": "TRYMNGSGOA"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "XTRSAXIUMN"
              },
              "source": {
                "name": "XNOBLTAWXO"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Read Account__

#### __Query__

```graphql
query read { root { accounts { edges { node { url } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "url": "http://SOJSQDCKVW.com"
            }
          },
          {
            "node": {
              "url": "http://PLBQTXMFBO.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Create Account__

#### __Query__

```graphql
mutation create { createAccount(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { account { id } } }
```

#### __Result__

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

### __Read Collection Account__

#### __Query__

```graphql
query read { root { accounts { edges { node { medias { edges { node { url } } } } } } } }
```

#### __Result__

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
                      "url": "http://DYBQVFLSQV.com"
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

## Api Key
### __Update Api Key__

#### __Query__

```graphql
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
", application: "bar" }) { api_key { application } } }
```

#### __Result__

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

### __Read Api Key__

#### __Query__

```graphql
query read { root { api_keys { edges { node { application } } } } }
```

#### __Result__

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

### __Create Api Key__

#### __Query__

```graphql
mutation create { createApiKey(input: {application: "test", clientMutationId: "1"}) { api_key { id } } }
```

#### __Result__

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

### __Destroy Api Key__

#### __Query__

```graphql
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzE=\n"
    }
  }
}
```

## Comment
### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVllUaTFPLTVjcG1wUlhNQXg4aA==\n"
      }
    }
  }
}
```

### __Destroy Comment__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUaTFpSjVjcG1wUlhNQXg4aQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVllUaTFpSjVjcG1wUlhNQXg4aQ==\n"
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUaTJ5YzVjcG1wUlhNQXg4ag==
", text: "bar" }) { comment { text } } }
```

#### __Result__

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

### __Read Comment__

#### __Query__

```graphql
query read { root { comments { edges { node { text } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "comments": {
        "edges": [
          {
            "node": {
              "text": "ONPALICZBWBJJWGDPERLLGOREVIUAHAOHRESRRNQFHKFSSAUNC"
            }
          },
          {
            "node": {
              "text": "FWRTZSCHNQLZJVNXMYOWQAVYBDPYCFJSNIBFCRBTQANEFYHGUU"
            }
          }
        ]
      }
    }
  }
}
```

## Media
### __Read Object Media__

#### __Query__

```graphql
query read { root { medias { edges { node { account { url }, user { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "account": {
                "url": "http://JCEBTVALHA.com"
              },
              "user": {
                "name": "JSJSGXVXPK"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://OYHYKPNVZK.com"
              },
              "user": {
                "name": "KSHQDIHYSP"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Read Media__

#### __Query__

```graphql
query read { root { medias { edges { node { url } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "url": "http://AHSSXESEWP.com"
            }
          },
          {
            "node": {
              "url": "http://SRGNZIZNQX.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Media__

#### __Query__

```graphql
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMQ==\n"
    }
  }
}
```

### __Read Collection Media__

#### __Query__

```graphql
query read { root { medias { edges { node { projects { edges { node { title } } } } } } } }
```

#### __Result__

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
                      "title": "EXSOBBRLVQ"
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

### __Update Media__

#### __Query__

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 2 }) { media { user_id } } }
```

#### __Result__

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

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { media { id } } }
```

#### __Result__

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

## Project
### __Read Object Project__

#### __Query__

```graphql
query read { root { projects { edges { node { user { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "JLRKKQLTBE"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "IGWTNTWEXU"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Project__

#### __Query__

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8x\n"
    }
  }
}
```

### __Update Project__

#### __Query__

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
", title: "bar" }) { project { title } } }
```

#### __Result__

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

### __Create Project__

#### __Query__

```graphql
mutation create { createProject(input: {title: "test", description: "test", clientMutationId: "1"}) { project { id } } }
```

#### __Result__

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

### __Read Project__

#### __Query__

```graphql
query read { root { projects { edges { node { title } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "title": "TJWWPJFLYO"
            }
          },
          {
            "node": {
              "title": "PORAURHLSC"
            }
          }
        ]
      }
    }
  }
}
```

### __Read Collection Project__

#### __Query__

```graphql
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

#### __Result__

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
                      "name": "XMZMXYFXTM"
                    }
                  },
                  {
                    "node": {
                      "name": "RCNZTLRAUV"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://MGCMJGQJMR.com"
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

## Project Source
### __Update Project Source__

#### __Query__

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 2 }) { project_source { source_id } } }
```

#### __Result__

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

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 1, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

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

### __Read Project Source__

#### __Query__

```graphql
query read { root { project_sources { edges { node { source_id } } } } }
```

#### __Result__

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

### __Read Object Project Source__

#### __Query__

```graphql
query read { root { project_sources { edges { node { project { title }, source { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "BLLFIVYQKV"
              },
              "source": {
                "name": "LAVGPPARYH"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "DZCXGOJOLM"
              },
              "source": {
                "name": "ZBBCOPSXDP"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Project Source__

#### __Query__

```graphql
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8x\n"
    }
  }
}
```

## Source
### __Create Source__

#### __Query__

```graphql
mutation create { createSource(input: {name: "test", slogan: "test", clientMutationId: "1"}) { source { id } } }
```

#### __Result__

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

### __Read Source__

#### __Query__

```graphql
query read { root { sources { edges { node { name } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "name": "TBREVHNULE"
            }
          },
          {
            "node": {
              "name": "MMMTSSMWXE"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Source__

#### __Query__

```graphql
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzI=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzI=\n"
    }
  }
}
```

### __Update Source__

#### __Query__

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzI=
", name: "bar" }) { source { name } } }
```

#### __Result__

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

### __Read Collection Source__

#### __Query__

```graphql
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

#### __Result__

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
                      "title": "GNHOUIWFAO"
                    }
                  },
                  {
                    "node": {
                      "title": "ZOCBTKDYAR"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://QZQADVHYVH.com"
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

## Team
### __Create Team__

#### __Query__

```graphql
mutation create { createTeam(input: {name: "test", description: "test", clientMutationId: "1"}) { team { id } } }
```

#### __Result__

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

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8x
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8x\n"
    }
  }
}
```

### __Read Team__

#### __Query__

```graphql
query read { root { teams { edges { node { name } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "name": "FAMRJKEJAY"
            }
          },
          {
            "node": {
              "name": "CNFUXYSTQF"
            }
          }
        ]
      }
    }
  }
}
```

### __Update Team__

#### __Query__

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8x
", name: "bar" }) { team { name } } }
```

#### __Result__

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

### __Read Collection Team__

#### __Query__

```graphql
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } } } } } } }
```

#### __Result__

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
                      "name": "ZITCMGRJOU"
                    }
                  },
                  {
                    "node": {
                      "name": "PZMYHCNPOQ"
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

## Team User
### __Destroy Team User__

#### __Query__

```graphql
mutation destroy { destroyTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeamUser": {
      "deletedId": "VGVhbVVzZXIvMQ==\n"
    }
  }
}
```

### __Update Team User__

#### __Query__

```graphql
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
", team_id: 2 }) { team_user { team_id } } }
```

#### __Result__

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

### __Read Team User__

#### __Query__

```graphql
query read { root { team_users { edges { node { user_id } } } } }
```

#### __Result__

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

### __Read Object Team User__

#### __Query__

```graphql
query read { root { team_users { edges { node { team { name }, user { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "MBZHQXNUCJ"
              },
              "user": {
                "name": "AQJPKIBZOA"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "UYBVRPMIAP"
              },
              "user": {
                "name": "ABOLLMWZMC"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 1, user_id: 1, clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

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

## User
### __Read User__

#### __Query__

```graphql
query read { root { users { edges { node { email } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "users": {
        "edges": [
          {
            "node": {
              "email": "arefrzttpj@leokszmmkl.com"
            }
          },
          {
            "node": {
              "email": "yzysjpknpc@xrbgfmptse.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy User__

#### __Query__

```graphql
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8y
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8y\n"
    }
  }
}
```

### __Update User__

#### __Query__

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8y
", name: "Bar" }) { user { name } } }
```

#### __Result__

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

### __Create User__

#### __Query__

```graphql
mutation create { createUser(input: {email: "user@test.test", login: "test", name: "Test", password: "12345678", password_confirmation: "12345678", clientMutationId: "1"}) { user { id } } }
```

#### __Result__

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

