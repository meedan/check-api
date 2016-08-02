# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Create Account</strong>](#create-account)
    * [<strong>Query</strong>](#query)
    * [<strong>Result</strong>](#result)
  * [<strong>Read Account</strong>](#read-account)
    * [<strong>Query</strong>](#query-1)
    * [<strong>Result</strong>](#result-1)
  * [<strong>Destroy Account</strong>](#destroy-account)
    * [<strong>Query</strong>](#query-2)
    * [<strong>Result</strong>](#result-2)
  * [<strong>Read Object Account</strong>](#read-object-account)
    * [<strong>Query</strong>](#query-3)
    * [<strong>Result</strong>](#result-3)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
    * [<strong>Query</strong>](#query-4)
    * [<strong>Result</strong>](#result-4)
  * [<strong>Update Account</strong>](#update-account)
    * [<strong>Query</strong>](#query-5)
    * [<strong>Result</strong>](#result-5)
* [Annotation](#annotation)
  * [<strong>Read Annotation</strong>](#read-annotation)
    * [<strong>Query</strong>](#query-6)
    * [<strong>Result</strong>](#result-6)
  * [<strong>Read Object Annotation</strong>](#read-object-annotation)
    * [<strong>Query</strong>](#query-7)
    * [<strong>Result</strong>](#result-7)
  * [<strong>Destroy Annotation</strong>](#destroy-annotation)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
* [Api Key](#api-key)
  * [<strong>Read Api Key</strong>](#read-api-key)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Destroy Api Key</strong>](#destroy-api-key)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Update Api Key</strong>](#update-api-key)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
  * [<strong>Create Api Key</strong>](#create-api-key)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
* [Comment](#comment)
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Media](#media)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Update Media</strong>](#update-media)
    * [<strong>Query</strong>](#query-18)
    * [<strong>Result</strong>](#result-18)
  * [<strong>Read Media</strong>](#read-media)
    * [<strong>Query</strong>](#query-19)
    * [<strong>Result</strong>](#result-19)
  * [<strong>Create Media</strong>](#create-media)
    * [<strong>Query</strong>](#query-20)
    * [<strong>Result</strong>](#result-20)
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-21)
    * [<strong>Result</strong>](#result-21)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-22)
    * [<strong>Result</strong>](#result-22)
* [Project](#project)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
* [Project Source](#project-source)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
* [Source](#source)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
  * [<strong>Create Source</strong>](#create-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
  * [<strong>Destroy Source</strong>](#destroy-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
* [Status](#status)
  * [<strong>Destroy Status</strong>](#destroy-status)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
  * [<strong>Update Status</strong>](#update-status)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
  * [<strong>Create Status</strong>](#create-status)
    * [<strong>Query</strong>](#query-41)
    * [<strong>Result</strong>](#result-41)
  * [<strong>Read Status</strong>](#read-status)
    * [<strong>Query</strong>](#query-42)
    * [<strong>Result</strong>](#result-42)
* [Tag](#tag)
  * [<strong>Create Tag</strong>](#create-tag)
    * [<strong>Query</strong>](#query-43)
    * [<strong>Result</strong>](#result-43)
  * [<strong>Destroy Tag</strong>](#destroy-tag)
    * [<strong>Query</strong>](#query-44)
    * [<strong>Result</strong>](#result-44)
  * [<strong>Update Tag</strong>](#update-tag)
    * [<strong>Query</strong>](#query-45)
    * [<strong>Result</strong>](#result-45)
  * [<strong>Read Tag</strong>](#read-tag)
    * [<strong>Query</strong>](#query-46)
    * [<strong>Result</strong>](#result-46)
* [Team](#team)
  * [<strong>Destroy Team</strong>](#destroy-team)
    * [<strong>Query</strong>](#query-47)
    * [<strong>Result</strong>](#result-47)
  * [<strong>Read Collection Team</strong>](#read-collection-team)
    * [<strong>Query</strong>](#query-48)
    * [<strong>Result</strong>](#result-48)
  * [<strong>Update Team</strong>](#update-team)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
  * [<strong>Read Team</strong>](#read-team)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-51)
    * [<strong>Result</strong>](#result-51)
* [Team User](#team-user)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-52)
    * [<strong>Result</strong>](#result-52)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-53)
    * [<strong>Result</strong>](#result-53)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-54)
    * [<strong>Result</strong>](#result-54)
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Destroy Team User</strong>](#destroy-team-user)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
* [User](#user)
  * [<strong>Create User</strong>](#create-user)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)

## Account

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
              "url": "http://SSVUQRGATA.com"
            }
          },
          {
            "node": {
              "url": "http://ENJBICUDRD.com"
            }
          }
        ]
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
                "name": "YAREZFJOVJ"
              },
              "source": {
                "name": "TNDQYYQBRO"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "HJLHBZBRJM"
              },
              "source": {
                "name": "ARJBSIMMKM"
              }
            }
          }
        ]
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
                      "url": "http://NSAKHMYMEO.com"
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

### __Update Account__

#### __Query__

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 3 }) { account { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 3
      }
    }
  }
}
```


## Annotation

### __Read Annotation__

#### __Query__

```graphql
query read { root { annotations { edges { node { context_id } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "annotations": {
        "edges": [
          {
            "node": {
              "context_id": null
            }
          },
          {
            "node": {
              "context_id": null
            }
          }
        ]
      }
    }
  }
}
```

### __Read Object Annotation__

#### __Query__

```graphql
query read { root { annotations { edges { node { annotator { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "annotations": {
        "edges": [
          {
            "node": {
              "annotator": {
                "name": "YVVTSLIDQP"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "IAOQYRPSVR"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Annotation__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlpDMVJSek9MVXhLOVBMZTk5Ug==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVlpDMVJSek9MVXhLOVBMZTk5Ug==\n"
    }
  }
}
```


## Api Key

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

### __Destroy Api Key__

#### __Query__

```graphql
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzM=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzM=\n"
    }
  }
}
```

### __Update Api Key__

#### __Query__

```graphql
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzM=
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
        "id": "QXBpS2V5LzM=\n"
      }
    }
  }
}
```


## Comment

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "Source", annotated_id: "2", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVlpDMUw1b09MVXhLOVBMZTk5SQ==\n"
      }
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlpDMU9ZOU9MVXhLOVBMZTk5Tg==
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

### __Destroy Comment__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlpDMVNBeE9MVXhLOVBMZTk5Uw==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVlpDMVNBeE9MVXhLOVBMZTk5Uw==\n"
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
              "text": "ECGSKOLGAMJTYTWNKJMQVGFIVHXVJOBSVGKTMSTDFHDCKYJJCZ"
            }
          },
          {
            "node": {
              "text": "JELLPHRYXEAZHDJRJVEYLOSETXQDFZXYEVRPHZTVHIPHCJDZXN"
            }
          }
        ]
      }
    }
  }
}
```


## Media

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

### __Update Media__

#### __Query__

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 3 }) { media { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateMedia": {
      "media": {
        "user_id": 3
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
              "url": "http://ZFDIXJVYMC.com"
            }
          },
          {
            "node": {
              "url": "http://AILGVSHMID.com"
            }
          }
        ]
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
                      "title": "YZAXAQZESK"
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
                "url": "http://ILFMDCKJJM.com"
              },
              "user": {
                "name": "ZTVZGPZYVC"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://LNYADWQIMC.com"
              },
              "user": {
                "name": "HLOBBKRTPU"
              }
            }
          }
        ]
      }
    }
  }
}
```


## Project

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
                      "name": "WROTZGKJUG"
                    }
                  },
                  {
                    "node": {
                      "name": "KMXKDTEBOW"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://WKIGLDQVUD.com"
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
                "name": "WEXZKVXYQR"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "WKFNGSVBWC"
              }
            }
          }
        ]
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
              "title": "HLMNWHJHHB"
            }
          },
          {
            "node": {
              "title": "QSSTQFJCPZ"
            }
          }
        ]
      }
    }
  }
}
```


## Project Source

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
              "source_id": 4
            }
          },
          {
            "node": {
              "source_id": 6
            }
          }
        ]
      }
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 2, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
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

### __Update Project Source__

#### __Query__

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 3 }) { project_source { source_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "source_id": 3
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
                "title": "COEWEDDIGM"
              },
              "source": {
                "name": "SQSDTMMUXZ"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "AANOCNPXNW"
              },
              "source": {
                "name": "BSEJFKJOPF"
              }
            }
          }
        ]
      }
    }
  }
}
```


## Source

### __Update Source__

#### __Query__

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzM=
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
        "id": "U291cmNlLzM=\n"
      }
    }
  }
}
```

### __Destroy Source__

#### __Query__

```graphql
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzM=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzM=\n"
    }
  }
}
```

### __Read Source__

#### __Query__

```graphql
query read { root { sources { edges { node { image } } } } }
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
              "image": ""
            }
          },
          {
            "node": {
              "image": ""
            }
          }
        ]
      }
    }
  }
}
```

### __Read Collection Source__

#### __Query__

```graphql
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } }, annotations { edges { node { content } } }, medias { edges { node { url } } }, collaborators { edges { node { name } } }, tags { edges { node { tag } } }, comments { edges { node { text } } } } } } } }
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
                      "title": "QKQRNWXHSM"
                    }
                  },
                  {
                    "node": {
                      "title": "XOUEMFKQYV"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://UMYBXIPSTW.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://ACGULYZTSO.com"
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
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"OUIRTPUREPLKEFFURESAGFLHTBMHCFMQNZIXEBXZRTDNCNEJIF\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"FSGGDSAUTRYBQLQIYDZUAWGYEXNVIXIOXYVRYIQBYYJNFPPBTR\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"WDKFBUXBNORDTTEKVYGHSHVGZXOIBXEDKDITVGJPGITAKUKVTZ\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://YRCRSESKSF.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "ULLVANXQXC"
                    }
                  },
                  {
                    "node": {
                      "name": "YLUSCQORJA"
                    }
                  },
                  {
                    "node": {
                      "name": "VFFTHPGHXP"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "OUIRTPUREPLKEFFURESAGFLHTBMHCFMQNZIXEBXZRTDNCNEJIF"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "FSGGDSAUTRYBQLQIYDZUAWGYEXNVIXIOXYVRYIQBYYJNFPPBTR"
                    }
                  },
                  {
                    "node": {
                      "text": "WDKFBUXBNORDTTEKVYGHSHVGZXOIBXEDKDITVGJPGITAKUKVTZ"
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"LQONHSEKVUSTBQFMRDIHJEFLJLKBFXJNMKSVXETBDQHGVQDNDF\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "GBWQGQPCOO"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "LQONHSEKVUSTBQFMRDIHJEFLJLKBFXJNMKSVXETBDQHGVQDNDF"
                    }
                  }
                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"DIGEAJFCGTPSGAMTIJVYPHIWMPOQMXVYZCPJAFQLZQIOTFYFSY\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "VTCDGPMKJG"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "DIGEAJFCGTPSGAMTIJVYPHIWMPOQMXVYZCPJAFQLZQIOTFYFSY"
                    }
                  }
                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
                  {
                    "node": {
                      "url": "http://KEKXMMPKDI.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [

                ]
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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
              },
              "annotations": {
                "edges": [

                ]
              },
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
                "edges": [

                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
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


## Status

### __Destroy Status__

#### __Query__

```graphql
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWWkMxTTk1T0xVeEs5UExlOTlL
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWWkMxTTk1T0xVeEs5UExlOTlL\n"
    }
  }
}
```

### __Update Status__

#### __Query__

```graphql
mutation update { updateStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWWkMxVkJxT0xVeEs5UExlOTlX
", status: "Not Credible" }) { status { status } } }
```

#### __Result__

```json
{
  "data": {
    "updateStatus": {
      "status": {
        "status": "Not Credible"
      }
    }
  }
}
```

### __Create Status__

#### __Query__

```graphql
mutation create { createStatus(input: {status: "Credible", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWWkMxVmpMT0xVeEs5UExlOTlY\n"
      }
    }
  }
}
```

### __Read Status__

#### __Query__

```graphql
query read { root { statuses { edges { node { status } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "statuses": {
        "edges": [
          {
            "node": {
              "status": "Credible"
            }
          },
          {
            "node": {
              "status": "Credible"
            }
          }
        ]
      }
    }
  }
}
```


## Tag

### __Create Tag__

#### __Query__

```graphql
mutation create { createTag(input: {tag: "egypt", annotated_type: "Source", annotated_id: "2", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWWkMxS01HT0xVeEs5UExlOTlG\n"
      }
    }
  }
}
```

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWWkMxTWNLT0xVeEs5UExlOTlK
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWWkMxTWNLT0xVeEs5UExlOTlK\n"
    }
  }
}
```

### __Update Tag__

#### __Query__

```graphql
mutation update { updateTag(input: { clientMutationId: "1", id: "VGFnL0FWWkMxUEtaT0xVeEs5UExlOTlP
", tag: "Egypt" }) { tag { tag } } }
```

#### __Result__

```json
{
  "data": {
    "updateTag": {
      "tag": {
        "tag": "Egypt"
      }
    }
  }
}
```

### __Read Tag__

#### __Query__

```graphql
query read { root { tags { edges { node { tag } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "tags": {
        "edges": [
          {
            "node": {
              "tag": "LQONHSEKVUSTBQFMRDIHJEFLJLKBFXJNMKSVXETBDQHGVQDNDF"
            }
          },
          {
            "node": {
              "tag": "DIGEAJFCGTPSGAMTIJVYPHIWMPOQMXVYZCPJAFQLZQIOTFYFSY"
            }
          }
        ]
      }
    }
  }
}
```


## Team

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
                      "name": "BKKIJXLICS"
                    }
                  },
                  {
                    "node": {
                      "name": "KARICMBJMC"
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
              "name": "VUXSZGCWDF"
            }
          },
          {
            "node": {
              "name": "PPPXOXEUJC"
            }
          }
        ]
      }
    }
  }
}
```

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


## Team User

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
              "user_id": 3
            }
          },
          {
            "node": {
              "user_id": 4
            }
          }
        ]
      }
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

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 1, user_id: 2, clientMutationId: "1"}) { team_user { id } } }
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
                "name": "XBZOPFHUZV"
              },
              "user": {
                "name": "NNPNLCBSGW"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "JVIOMETGKQ"
              },
              "user": {
                "name": "CCMQNRBAFG"
              }
            }
          }
        ]
      }
    }
  }
}
```

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


## User

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
        "id": "VXNlci8z\n"
      }
    }
  }
}
```

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
              "email": "peiaktsyjl@inasaixnid.com"
            }
          },
          {
            "node": {
              "email": "dcamenspfj@fmvwaubdvl.com"
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
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8z
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8z\n"
    }
  }
}
```

### __Update User__

#### __Query__

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8z
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

### __Read Collection User__

#### __Query__

```graphql
query read { root { users { edges { node { teams { edges { node { name } } }, projects { edges { node { title } } } } } } } }
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
              "teams": {
                "edges": [
                  {
                    "node": {
                      "name": "VBGQZULPFT"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "JCWOTFWOON"
                    }
                  }
                ]
              }
            }
          },
          {
            "node": {
              "teams": {
                "edges": [

                ]
              },
              "projects": {
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

### __Read Object User__

#### __Query__

```graphql
query read { root { users { edges { node { source { name } } } } } }
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
              "source": {
                "name": "PDPLDLOVOP"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "UGQKOKZPCR"
              }
            }
          }
        ]
      }
    }
  }
}
```

