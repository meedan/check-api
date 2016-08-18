# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
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
  * [<strong>Create Account</strong>](#create-account)
    * [<strong>Query</strong>](#query-4)
    * [<strong>Result</strong>](#result-4)
  * [<strong>Update Account</strong>](#update-account)
    * [<strong>Query</strong>](#query-5)
    * [<strong>Result</strong>](#result-5)
* [Annotation](#annotation)
  * [<strong>Read Annotation</strong>](#read-annotation)
    * [<strong>Query</strong>](#query-6)
    * [<strong>Result</strong>](#result-6)
  * [<strong>Destroy Annotation</strong>](#destroy-annotation)
    * [<strong>Query</strong>](#query-7)
    * [<strong>Result</strong>](#result-7)
  * [<strong>Read Object Annotation</strong>](#read-object-annotation)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
* [Api Key](#api-key)
  * [<strong>Create Api Key</strong>](#create-api-key)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Update Api Key</strong>](#update-api-key)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Read Api Key</strong>](#read-api-key)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
  * [<strong>Destroy Api Key</strong>](#destroy-api-key)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
* [Comment](#comment)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Contact](#contact)
  * [<strong>Create Contact</strong>](#create-contact)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Destroy Contact</strong>](#destroy-contact)
    * [<strong>Query</strong>](#query-18)
    * [<strong>Result</strong>](#result-18)
  * [<strong>Update Contact</strong>](#update-contact)
    * [<strong>Query</strong>](#query-19)
    * [<strong>Result</strong>](#result-19)
  * [<strong>Read Object Contact</strong>](#read-object-contact)
    * [<strong>Query</strong>](#query-20)
    * [<strong>Result</strong>](#result-20)
  * [<strong>Read Contact</strong>](#read-contact)
    * [<strong>Query</strong>](#query-21)
    * [<strong>Result</strong>](#result-21)
* [Media](#media)
  * [<strong>Create Media</strong>](#create-media)
    * [<strong>Query</strong>](#query-22)
    * [<strong>Result</strong>](#result-22)
  * [<strong>Read Media</strong>](#read-media)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
  * [<strong>Get By Id Media</strong>](#get-by-id-media)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Update Media</strong>](#update-media)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
* [Project](#project)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
* [Project Source](#project-source)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
* [Source](#source)
  * [<strong>Destroy Source</strong>](#destroy-source)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
    * [<strong>Query</strong>](#query-41)
    * [<strong>Result</strong>](#result-41)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-42)
    * [<strong>Result</strong>](#result-42)
  * [<strong>Get By Id Source</strong>](#get-by-id-source)
    * [<strong>Query</strong>](#query-43)
    * [<strong>Result</strong>](#result-43)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-44)
    * [<strong>Result</strong>](#result-44)
  * [<strong>Create Source</strong>](#create-source)
    * [<strong>Query</strong>](#query-45)
    * [<strong>Result</strong>](#result-45)
* [Status](#status)
  * [<strong>Update Status</strong>](#update-status)
    * [<strong>Query</strong>](#query-46)
    * [<strong>Result</strong>](#result-46)
  * [<strong>Create Status</strong>](#create-status)
    * [<strong>Query</strong>](#query-47)
    * [<strong>Result</strong>](#result-47)
  * [<strong>Destroy Status</strong>](#destroy-status)
    * [<strong>Query</strong>](#query-48)
    * [<strong>Result</strong>](#result-48)
  * [<strong>Read Status</strong>](#read-status)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
* [Tag](#tag)
  * [<strong>Create Tag</strong>](#create-tag)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Read Tag</strong>](#read-tag)
    * [<strong>Query</strong>](#query-51)
    * [<strong>Result</strong>](#result-51)
  * [<strong>Destroy Tag</strong>](#destroy-tag)
    * [<strong>Query</strong>](#query-52)
    * [<strong>Result</strong>](#result-52)
  * [<strong>Update Tag</strong>](#update-tag)
    * [<strong>Query</strong>](#query-53)
    * [<strong>Result</strong>](#result-53)
* [Team](#team)
  * [<strong>Destroy Team</strong>](#destroy-team)
    * [<strong>Query</strong>](#query-54)
    * [<strong>Result</strong>](#result-54)
  * [<strong>Read Team</strong>](#read-team)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
  * [<strong>Read Collection Team</strong>](#read-collection-team)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Update Team</strong>](#update-team)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
  * [<strong>Get By Id Team</strong>](#get-by-id-team)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
* [Team User](#team-user)
  * [<strong>Destroy Team User</strong>](#destroy-team-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-63)
    * [<strong>Result</strong>](#result-63)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-64)
    * [<strong>Result</strong>](#result-64)
* [User](#user)
  * [<strong>Get By Id User</strong>](#get-by-id-user)
    * [<strong>Query</strong>](#query-65)
    * [<strong>Result</strong>](#result-65)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-66)
    * [<strong>Result</strong>](#result-66)
  * [<strong>Create User</strong>](#create-user)
    * [<strong>Query</strong>](#query-67)
    * [<strong>Result</strong>](#result-67)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-68)
    * [<strong>Result</strong>](#result-68)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-69)
    * [<strong>Result</strong>](#result-69)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-70)
    * [<strong>Result</strong>](#result-70)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-71)
    * [<strong>Result</strong>](#result-71)

## Account

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
                      "url": "http://LJQHWCEAQY.com"
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
              "url": "http://TPBMTFFNUJ.com"
            }
          },
          {
            "node": {
              "url": "http://IWVLROYYBY.com"
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
                "name": "HRMSWRTXSV"
              },
              "source": {
                "name": "HHOWMTIPGW"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "GWZPJSXCBO"
              },
              "source": {
                "name": "LHZVUJCGJT"
              }
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

### __Destroy Annotation__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmFmcGwyNXNWSU9oeVFueFZSMg==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmFmcGwyNXNWSU9oeVFueFZSMg==\n"
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
                "name": "ZEDAAOLEAB"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "LOCCVUXDFY"
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

### __Destroy Comment__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmFmcGNLSnNWSU9oeVFueFZSbA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmFmcGNLSnNWSU9oeVFueFZSbA==\n"
    }
  }
}
```

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "Source", annotated_id: "1", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVmFmcGMyUnNWSU9oeVFueFZSbQ==\n"
      }
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmFmcGhVanNWSU9oeVFueFZSdg==
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
              "text": "UDQUNYJAWEHWNPUEBJGHAUUXKYVWLEUHOAKGDHKGYKYDTGDFLA"
            }
          },
          {
            "node": {
              "text": "HDNXEVMVLRXOKQKEGZORAUENVFMEJQGBXPEMIYBSCZYOAWLPCT"
            }
          }
        ]
      }
    }
  }
}
```


## Contact

### __Create Contact__

#### __Query__

```graphql
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 1, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC8x\n"
      }
    }
  }
}
```

### __Destroy Contact__

#### __Query__

```graphql
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC8x
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC8x\n"
    }
  }
}
```

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC8x
", location: "bar" }) { contact { location } } }
```

#### __Result__

```json
{
  "data": {
    "updateContact": {
      "contact": {
        "location": "bar"
      }
    }
  }
}
```

### __Read Object Contact__

#### __Query__

```graphql
query read { root { contacts { edges { node { team { name } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "contacts": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "ZTWOIXYRBR"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "BHPYMUHXEY"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Read Contact__

#### __Query__

```graphql
query read { root { contacts { edges { node { location } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "contacts": {
        "edges": [
          {
            "node": {
              "location": "PFRJOKOJLJ"
            }
          },
          {
            "node": {
              "location": "QXYTVBFPEI"
            }
          }
        ]
      }
    }
  }
}
```


## Media

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "http://EGNQVUMJTS.com", clientMutationId: "1"}) { media { id } } }
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
              "url": "http://CLYLHNYNOX.com"
            }
          },
          {
            "node": {
              "url": "http://UYNDORUTQW.com"
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
                "url": "http://TWHEPXJURQ.com"
              },
              "user": {
                "name": "LZXCGIJSGT"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://XVHOEJBCPQ.com"
              },
              "user": {
                "name": "GDIAPTPOJW"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Get By Id Media__

#### __Query__

```graphql
query GetById { media(id: "1") { user_id } }
```

#### __Result__

```json
{
  "data": {
    "media": {
      "user_id": 1
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

### __Read Collection Media__

#### __Query__

```graphql
query read { root { medias { edges { node { projects { edges { node { title } } }, annotations { edges { node { content } } }, tags { edges { node { tag } } } } } } } }
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
                      "title": "DZEJJQIMXF"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"DVXKEVHFIQIHUDNCIJIMRSGUVJTUOFDFCUUGVYAFQJZTVCYXRF\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"SBMBVZNFLVDBVPCNYEMANNUAVEZIHJLFNBFGRSNSQXLQXDDRQY\"}"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "DVXKEVHFIQIHUDNCIJIMRSGUVJTUOFDFCUUGVYAFQJZTVCYXRF"
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


## Project

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
              "title": "NLRLKCLQZU"
            }
          },
          {
            "node": {
              "title": "KRWUGUGXSA"
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
                      "name": "XNQBMTNCAF"
                    }
                  },
                  {
                    "node": {
                      "name": "AJFBVFZZWG"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://STJNUQXWWK.com"
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
                "name": "PBPZATELDZ"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "RGDIOMENSR"
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
                "title": "VAURSZGXML"
              },
              "source": {
                "name": "OOUGBOOXSD"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "CNXIKCSEDH"
              },
              "source": {
                "name": "JQWYEUXIFT"
              }
            }
          }
        ]
      }
    }
  }
}
```

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


## Source

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
                      "url": "http://UVIWEKJTPA.com"
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
                  {
                    "node": {
                      "content": "{\"text\":\"HDNXEVMVLRXOKQKEGZORAUENVFMEJQGBXPEMIYBSCZYOAWLPCT\"}"
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
                      "name": "BKCUFLKBPS"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "HDNXEVMVLRXOKQKEGZORAUENVFMEJQGBXPEMIYBSCZYOAWLPCT"
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
                      "content": "{\"text\":\"UDQUNYJAWEHWNPUEBJGHAUUXKYVWLEUHOAKGDHKGYKYDTGDFLA\"}"
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
                      "name": "XSLZCAIYZQ"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [

                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "UDQUNYJAWEHWNPUEBJGHAUUXKYVWLEUHOAKGDHKGYKYDTGDFLA"
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
                  {
                    "node": {
                      "title": "WIHIINBIYM"
                    }
                  },
                  {
                    "node": {
                      "title": "TVBMOXOMQN"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://HMCFBELFVX.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://GDGJPRLOCI.com"
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
                      "content": "{\"tag\":\"CIPUWAGLBRWNSEOZFQNEOGVTRWVGINHXAUGXTIXCBYEFTOJUWR\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"FUVLYVHIPXTZYMUCVFSDJKSQXFHOQJVXKQCZLPGHVDRLZHKHMJ\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"CERJAUVNKTSBYJCPNKAOYWDBTNFVRPJKHKMURMYMJHJMDUPGBH\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://GKHRCDCXWC.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "VEXVNYPHWG"
                    }
                  },
                  {
                    "node": {
                      "name": "KBPRZSJNEN"
                    }
                  },
                  {
                    "node": {
                      "name": "LSTHAEMICF"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "CIPUWAGLBRWNSEOZFQNEOGVTRWVGINHXAUGXTIXCBYEFTOJUWR"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "FUVLYVHIPXTZYMUCVFSDJKSQXFHOQJVXKQCZLPGHVDRLZHKHMJ"
                    }
                  },
                  {
                    "node": {
                      "text": "CERJAUVNKTSBYJCPNKAOYWDBTNFVRPJKHKMURMYMJHJMDUPGBH"
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

### __Get By Id Source__

#### __Query__

```graphql
query GetById { source(id: "2") { name } }
```

#### __Result__

```json
{
  "data": {
    "source": {
      "name": "Test"
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
              "image": null
            }
          },
          {
            "node": {
              "image": null
            }
          }
        ]
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
        "id": "U291cmNlLzI=\n"
      }
    }
  }
}
```


## Status

### __Update Status__

#### __Query__

```graphql
mutation update { updateStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWYWZwZElBc1ZJT2h5UW54VlJu
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
mutation create { createStatus(input: {status: "Credible", annotated_type: "Source", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWYWZwZklJc1ZJT2h5UW54VlJy\n"
      }
    }
  }
}
```

### __Destroy Status__

#### __Query__

```graphql
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWYWZwZ3dsc1ZJT2h5UW54VlJ1
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWYWZwZ3dsc1ZJT2h5UW54VlJ1\n"
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
mutation create { createTag(input: {tag: "egypt", annotated_type: "Source", annotated_id: "1", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWYWZwZTBzc1ZJT2h5UW54VlJx\n"
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
              "tag": "VCVZGYHJLLVFAENQHYEGIFVCXXEWABRAWEQHVKAEFMHSISNGRN"
            }
          },
          {
            "node": {
              "tag": "STGPGQGWFHNXXJONKVQNCCIMSEHPAIFYUERPDPMROGYNPCBRKS"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWYWZwaDR0c1ZJT2h5UW54VlJ3
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWYWZwaDR0c1ZJT2h5UW54VlJ3\n"
    }
  }
}
```

### __Update Tag__

#### __Query__

```graphql
mutation update { updateTag(input: { clientMutationId: "1", id: "VGFnL0FWYWZwcHo0c1ZJT2h5UW54VlI5
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
              "name": "UZGBTLWUSN"
            }
          },
          {
            "node": {
              "name": "EVUNCWASQB"
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
mutation create { createTeam(input: {name: "test", description: "test", subdomain: "test", clientMutationId: "1"}) { team { id } } }
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

### __Read Collection Team__

#### __Query__

```graphql
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } }, contacts { edges { node { location } } } } } } } }
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
                      "user_id": 1
                    }
                  },
                  {
                    "node": {
                      "user_id": 2
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "APKJZEPPLB"
                    }
                  },
                  {
                    "node": {
                      "name": "PRLOERZBEK"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "DHSKJHJYOR"
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
              },
              "contacts": {
                "edges": [

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
              },
              "contacts": {
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

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "1") { name } }
```

#### __Result__

```json
{
  "data": {
    "team": {
      "name": "Test"
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

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 1, user_id: 1, status: "member", clientMutationId: "1"}) { team_user { id } } }
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
                "name": "CCLHGCFJVM"
              },
              "user": {
                "name": "TCSYXYSPDF"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "UZKMPWMSVU"
              },
              "user": {
                "name": "CUWVUMXZGT"
              }
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


## User

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "2") { name } }
```

#### __Result__

```json
{
  "data": {
    "user": {
      "name": "Test"
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
                      "name": "IZMMBMJDIN"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "LAVOWBCUAU"
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
              "email": "hwoutlkajz@fqwbhytaeh.com"
            }
          },
          {
            "node": {
              "email": "hcwhibawxy@revecjzeyr.com"
            }
          }
        ]
      }
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
                "name": "YGLNGIGEET"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "LEZENGWXGR"
              }
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

