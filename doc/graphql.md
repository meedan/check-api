# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Update Account</strong>](#update-account)
    * [<strong>Query</strong>](#query)
    * [<strong>Result</strong>](#result)
  * [<strong>Create Account</strong>](#create-account)
    * [<strong>Query</strong>](#query-1)
    * [<strong>Result</strong>](#result-1)
  * [<strong>Read Account</strong>](#read-account)
    * [<strong>Query</strong>](#query-2)
    * [<strong>Result</strong>](#result-2)
  * [<strong>Read Object Account</strong>](#read-object-account)
    * [<strong>Query</strong>](#query-3)
    * [<strong>Result</strong>](#result-3)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
    * [<strong>Query</strong>](#query-4)
    * [<strong>Result</strong>](#result-4)
* [Annotation](#annotation)
  * [<strong>Destroy Annotation</strong>](#destroy-annotation)
    * [<strong>Query</strong>](#query-5)
    * [<strong>Result</strong>](#result-5)
  * [<strong>Read Annotation</strong>](#read-annotation)
    * [<strong>Query</strong>](#query-6)
    * [<strong>Result</strong>](#result-6)
  * [<strong>Read Object Annotation</strong>](#read-object-annotation)
    * [<strong>Query</strong>](#query-7)
    * [<strong>Result</strong>](#result-7)
* [Comment](#comment)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
* [Contact](#contact)
  * [<strong>Destroy Contact</strong>](#destroy-contact)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
  * [<strong>Update Contact</strong>](#update-contact)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Create Contact</strong>](#create-contact)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Read Contact</strong>](#read-contact)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Read Object Contact</strong>](#read-object-contact)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Media](#media)
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Get By Id Media</strong>](#get-by-id-media)
    * [<strong>Query</strong>](#query-18)
    * [<strong>Result</strong>](#result-18)
  * [<strong>Update Media</strong>](#update-media)
    * [<strong>Query</strong>](#query-19)
    * [<strong>Result</strong>](#result-19)
  * [<strong>Read Media</strong>](#read-media)
    * [<strong>Query</strong>](#query-20)
    * [<strong>Result</strong>](#result-20)
  * [<strong>Read Media</strong>](#read-media-1)
    * [<strong>Query</strong>](#query-21)
    * [<strong>Result</strong>](#result-21)
  * [<strong>Read Media</strong>](#read-media-2)
    * [<strong>Query</strong>](#query-22)
    * [<strong>Result</strong>](#result-22)
  * [<strong>Read Media</strong>](#read-media-3)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Create Media</strong>](#create-media)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
* [Project](#project)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
* [Project Source](#project-source)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
* [Source](#source)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
  * [<strong>Get By Id Source</strong>](#get-by-id-source)
    * [<strong>Query</strong>](#query-41)
    * [<strong>Result</strong>](#result-41)
  * [<strong>Create Source</strong>](#create-source)
    * [<strong>Query</strong>](#query-42)
    * [<strong>Result</strong>](#result-42)
* [Status](#status)
  * [<strong>Create Status</strong>](#create-status)
    * [<strong>Query</strong>](#query-43)
    * [<strong>Result</strong>](#result-43)
  * [<strong>Read Status</strong>](#read-status)
    * [<strong>Query</strong>](#query-44)
    * [<strong>Result</strong>](#result-44)
  * [<strong>Destroy Status</strong>](#destroy-status)
    * [<strong>Query</strong>](#query-45)
    * [<strong>Result</strong>](#result-45)
* [Tag](#tag)
  * [<strong>Read Tag</strong>](#read-tag)
    * [<strong>Query</strong>](#query-46)
    * [<strong>Result</strong>](#result-46)
  * [<strong>Create Tag</strong>](#create-tag)
    * [<strong>Query</strong>](#query-47)
    * [<strong>Result</strong>](#result-47)
  * [<strong>Destroy Tag</strong>](#destroy-tag)
    * [<strong>Query</strong>](#query-48)
    * [<strong>Result</strong>](#result-48)
* [Team](#team)
  * [<strong>Update Team</strong>](#update-team)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
  * [<strong>Get By Id Team</strong>](#get-by-id-team)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-51)
    * [<strong>Result</strong>](#result-51)
  * [<strong>Destroy Team</strong>](#destroy-team)
    * [<strong>Query</strong>](#query-52)
    * [<strong>Result</strong>](#result-52)
  * [<strong>Read Collection Team</strong>](#read-collection-team)
    * [<strong>Query</strong>](#query-53)
    * [<strong>Result</strong>](#result-53)
  * [<strong>Read Team</strong>](#read-team)
    * [<strong>Query</strong>](#query-54)
    * [<strong>Result</strong>](#result-54)
* [Team User](#team-user)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
* [User](#user)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
  * [<strong>Get By Id User</strong>](#get-by-id-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-63)
    * [<strong>Result</strong>](#result-63)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-64)
    * [<strong>Result</strong>](#result-64)

## Account

### __Update Account__

#### __Query__

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC81NzI=
", user_id: 4754 }) { account { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 4754
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
        "id": "QWNjb3VudC81NzU=\n"
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
              "url": "http://AYDMKHSIWV.com"
            }
          },
          {
            "node": {
              "url": "http://EHFVTKRAAW.com"
            }
          }
        ]
      }
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
                "name": "GTOZHBHHWR"
              },
              "source": {
                "name": "PAHMDKYMVS"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "WASUNCUVUP"
              },
              "source": {
                "name": "CTCNBKRPPU"
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
                      "url": "http://BOJJEFOKUN.com"
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


## Annotation

### __Destroy Annotation__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmRuX3VVV0dRNVRyWGM4cWRIcA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmRuX3VVV0dRNVRyWGM4cWRIcA==\n"
    }
  }
}
```

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
              "context_id": "2093"
            }
          },
          {
            "node": {
              "context_id": "2094"
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
                "name": "CUDVHDOCUV"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "ABJKYOGPFA"
              }
            }
          }
        ]
      }
    }
  }
}
```


## Comment

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
              "text": "ZIKSQIIVHVBVKWUTDHEGZSKDNEROQLRDNTATWMJFJRUXFIAOSF"
            }
          },
          {
            "node": {
              "text": "QFZZJQRNEZRFQAFUHVOBAEPBBVXMOOQUUCZMUFUXUDONXXCXMX"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Comment__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmRuX3lBcEdRNVRyWGM4cWRIdA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmRuX3lBcEdRNVRyWGM4cWRIdA==\n"
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmRuX3lsOUdRNVRyWGM4cWRIdQ==
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

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "Project", annotated_id: "2077", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVmRuX3pOWUdRNVRyWGM4cWRIdg==\n"
      }
    }
  }
}
```


## Contact

### __Destroy Contact__

#### __Query__

```graphql
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC83MA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC83MA==\n"
    }
  }
}
```

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC83MQ==
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

### __Create Contact__

#### __Query__

```graphql
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 2292, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC83Mw==\n"
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
              "location": "WCVCHKQVOL"
            }
          },
          {
            "node": {
              "location": "LWAIOOXRVN"
            }
          }
        ]
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
                "name": "BHLUPJPGTS"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "EVFHNRNYZB"
              }
            }
          }
        ]
      }
    }
  }
}
```


## Media

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
                      "title": "QIPQSHVOZQ"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"URRBKIFAYEJRSNANDTORDNVTTVMGWRQHDQPBEHRGUZPSAEOGZM\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"MGEDTESCJLIFNLDJEULDADHBAKRBGFOMSFFNHTBCJEWWWVVXLV\"}"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "URRBKIFAYEJRSNANDTORDNVTTVMGWRQHDQPBEHRGUZPSAEOGZM"
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

### __Get By Id Media__

#### __Query__

```graphql
query GetById { media(id: "396") { user_id } }
```

#### __Result__

```json
{
  "data": {
    "media": {
      "user_id": 4796
    }
  }
}
```

### __Update Media__

#### __Query__

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMzk4
", user_id: 4835 }) { media { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateMedia": {
      "media": {
        "user_id": 4835
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
              "url": "http://DKLIBNMSYD.com"
            }
          },
          {
            "node": {
              "url": "http://IHBIODOJNR.com"
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
query read { root { medias { edges { node { jsondata } } } } }
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
              "jsondata": "{\"url\":\"http://WJCWFXEHMO.com\",\"type\":\"item\"}"
            }
          },
          {
            "node": {
              "jsondata": "{\"url\":\"http://DFLAODUILQ.com\",\"type\":\"item\"}"
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
query read { root { medias { edges { node { published } } } } }
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
              "published": "1474918546"
            }
          },
          {
            "node": {
              "published": "1474918546"
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
query read { root { medias { edges { node { last_status } } } } }
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
              "last_status": "Undetermined"
            }
          },
          {
            "node": {
              "last_status": "Undetermined"
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
mutation create { createMedia(input: {url: "http://BHYDHFBQZT.com", project_id: 2078, clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvNDA4\n"
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
                "url": "http://FZSOWDEVSY.com"
              },
              "user": {
                "name": "PVQXSFSDEA"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://ATTNARTEGB.com"
              },
              "user": {
                "name": "VHAEYPQVPB"
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
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvNDEy
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvNDEy\n"
    }
  }
}
```


## Project

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
        "id": "UHJvamVjdC8xOTk0\n"
      }
    }
  }
}
```

### __Read Object Project__

#### __Query__

```graphql
query read { root { projects { edges { node { team { name } } } } } }
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
              "team": {
                "name": "MCFPXLABZW"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "GLLGVHJGQO"
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
              "title": "OMZSCFBTNT"
            }
          },
          {
            "node": {
              "title": "ECWAUSWOBT"
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
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8yMDI2
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8yMDI2\n"
    }
  }
}
```

### __Read Collection Project__

#### __Query__

```graphql
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, annotations { edges { node { content } } } } } } } }
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
                      "name": "DYEDZWSPXS"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://WVODNTZCBS.com"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"LWXDVRNIUQTHYOBZLQGHYAUTYGOQPYDPFCSUIVYJHEZTCHUMWF\"}"
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

### __Update Project__

#### __Query__

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8yMDg5
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
              "source_id": 6017
            }
          },
          {
            "node": {
              "source_id": 6019
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
                "title": "RXWKXWFQYY"
              },
              "source": {
                "name": "QCCYGIDOID"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "XANMUOBSRG"
              },
              "source": {
                "name": "WNTGLZWUWL"
              }
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
mutation create { createProjectSource(input: {source_id: 6161, project_id: 2046, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS8xMTM=\n"
      }
    }
  }
}
```

### __Destroy Project Source__

#### __Query__

```graphql
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8xMTY=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8xMTY=\n"
    }
  }
}
```

### __Update Project Source__

#### __Query__

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8xMTc=
", project_id: 2105 }) { project_source { project_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "project_id": 2105
      }
    }
  }
}
```


## Source

### __Update Source__

#### __Query__

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzYwNDU=
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
                      "url": "http://LKLYYZTVRI.com"
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
                  {
                    "node": {
                      "title": "SYIEJBQYMP"
                    }
                  },
                  {
                    "node": {
                      "title": "HPQAMUPUIY"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://WLPBJLXCJS.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://LMLKMDOURW.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 2032
                    }
                  },
                  {
                    "node": {
                      "project_id": 2033
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"IUYQJOTFMRBTAXAAJUOCIOOCFZZVOBZLSPGRGSSWTONLFLIWCP\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"XSYZKYFSWSVODPJKRMLTYYRHEAPEEXWQSOWBPRVAXWWECXSBGB\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"VHJXBKEDSRFLDYMQTUOHCOJQPRSCRSRVERPQBZEKQGCFFOYCXN\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://LVHRVZDPTY.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "JOPPCEBDTA"
                    }
                  },
                  {
                    "node": {
                      "name": "XMUNSYLDLW"
                    }
                  },
                  {
                    "node": {
                      "name": "DBFZPXVZHA"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "IUYQJOTFMRBTAXAAJUOCIOOCFZZVOBZLSPGRGSSWTONLFLIWCP"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "XSYZKYFSWSVODPJKRMLTYYRHEAPEEXWQSOWBPRVAXWWECXSBGB"
                    }
                  },
                  {
                    "node": {
                      "text": "VHJXBKEDSRFLDYMQTUOHCOJQPRSCRSRVERPQBZEKQGCFFOYCXN"
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

### __Get By Id Source__

#### __Query__

```graphql
query GetById { source(id: "6224") { name } }
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
        "id": "U291cmNlLzYyNDE=\n"
      }
    }
  }
}
```


## Status

### __Create Status__

#### __Query__

```graphql
mutation create { createStatus(input: {status: "Credible", annotated_type: "Source", annotated_id: "6051", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWZG5fcHNIR1E1VHJYYzhxZEhq\n"
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

### __Destroy Status__

#### __Query__

```graphql
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWZG5fNEFkR1E1VHJYYzhxZEgz
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWZG5fNEFkR1E1VHJYYzhxZEgz\n"
    }
  }
}
```


## Tag

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
              "tag": "NSDCDQMFGVKEFFSIVCLQZUYSLCLPBZOJAFCUPZVVKEKNBFIAYG"
            }
          },
          {
            "node": {
              "tag": "MMCFMPZTHGAHRJSALCVGAPIDLXETBQYPGRWYNXLTZDKLBSBJGT"
            }
          }
        ]
      }
    }
  }
}
```

### __Create Tag__

#### __Query__

```graphql
mutation create { createTag(input: {tag: "egypt", annotated_type: "Source", annotated_id: "6048", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWZG5fcFdsR1E1VHJYYzhxZEhp\n"
      }
    }
  }
}
```

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWZG5fenFkR1E1VHJYYzhxZEh3
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWZG5fenFkR1E1VHJYYzhxZEh3\n"
    }
  }
}
```


## Team

### __Update Team__

#### __Query__

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8yMjU2
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
query GetById { team(id: "2267") { name } }
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
        "id": "VGVhbS8yMjcx\n"
      }
    }
  }
}
```

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8yMjg0
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8yMjg0\n"
    }
  }
}
```

### __Read Collection Team__

#### __Query__

```graphql
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } }, contacts { edges { node { location } } }, projects { edges { node { title } } } } } } } }
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
                      "user_id": 4922
                    }
                  },
                  {
                    "node": {
                      "user_id": 4923
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "ITYMTXMQGW"
                    }
                  },
                  {
                    "node": {
                      "name": "VOTZVQPLTD"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "GNAJHPXHCY"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "UGTPZWIOTK"
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
              },
              "projects": {
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
              },
              "projects": {
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
              "name": "KOINFMCGDV"
            }
          },
          {
            "node": {
              "name": "HLFKRQKYVW"
            }
          }
        ]
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
              "user_id": 4719
            }
          },
          {
            "node": {
              "user_id": 4720
            }
          },
          {
            "node": {
              "user_id": 4718
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
                "name": "BEORRXSXGI"
              },
              "user": {
                "name": "OOGPCWGVJC"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "NSMAOVMTMI"
              },
              "user": {
                "name": "NDGKOTOMZV"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "JMYDILIKXH"
              },
              "user": {
                "name": "ILVFVHCQPT"
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
mutation create { createTeamUser(input: {team_id: 2234, user_id: 4757, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvODE2\n"
      }
    }
  }
}
```

### __Update Team User__

#### __Query__

```graphql
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvODc1
", team_id: 2309 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 2309
      }
    }
  }
}
```


## User

### __Destroy User__

#### __Query__

```graphql
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci80NzEy
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci80NzEy\n"
    }
  }
}
```

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "4725") { name } }
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
query read { root { users { edges { node { teams { edges { node { name } } }, team_users { edges { node { role } } } } } } } }
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
                      "name": "KHCPBKFWTE"
                    }
                  },
                  {
                    "node": {
                      "name": "LCXOZBNOKW"
                    }
                  }
                ]
              },
              "team_users": {
                "edges": [
                  {
                    "node": {
                      "role": "contributor"
                    }
                  },
                  {
                    "node": {
                      "role": "contributor"
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
              "team_users": {
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
              "email": "flsfwadwxw@pgfrzdrgbi.com"
            }
          },
          {
            "node": {
              "email": "rnuvsdjfxt@dsvtsexqql.com"
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
query read { root { users { edges { node { source { name }, current_team { name } } } } } }
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
                "name": "JVQEKCVOMD"
              },
              "current_team": {
                "name": "KYSMQDPGET"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "CZZZWCCNPX"
              },
              "current_team": {
                "name": "KYSMQDPGET"
              }
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
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci80OTA2
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

