# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
    * [<strong>Query</strong>](#query)
    * [<strong>Result</strong>](#result)
  * [<strong>Create Account</strong>](#create-account)
    * [<strong>Query</strong>](#query-1)
    * [<strong>Result</strong>](#result-1)
  * [<strong>Read Account</strong>](#read-account)
    * [<strong>Query</strong>](#query-2)
    * [<strong>Result</strong>](#result-2)
  * [<strong>Update Account</strong>](#update-account)
    * [<strong>Query</strong>](#query-3)
    * [<strong>Result</strong>](#result-3)
  * [<strong>Read Object Account</strong>](#read-object-account)
    * [<strong>Query</strong>](#query-4)
    * [<strong>Result</strong>](#result-4)
* [Annotation](#annotation)
  * [<strong>Read Annotation</strong>](#read-annotation)
    * [<strong>Query</strong>](#query-5)
    * [<strong>Result</strong>](#result-5)
  * [<strong>Destroy Annotation</strong>](#destroy-annotation)
    * [<strong>Query</strong>](#query-6)
    * [<strong>Result</strong>](#result-6)
  * [<strong>Read Object Annotation</strong>](#read-object-annotation)
    * [<strong>Query</strong>](#query-7)
    * [<strong>Result</strong>](#result-7)
* [Comment](#comment)
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
* [Contact](#contact)
  * [<strong>Read Object Contact</strong>](#read-object-contact)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
  * [<strong>Destroy Contact</strong>](#destroy-contact)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Create Contact</strong>](#create-contact)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Update Contact</strong>](#update-contact)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Read Contact</strong>](#read-contact)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Media](#media)
  * [<strong>Create Media</strong>](#create-media)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Create Media</strong>](#create-media-1)
    * [<strong>Query</strong>](#query-18)
    * [<strong>Result</strong>](#result-18)
  * [<strong>Create Media</strong>](#create-media-2)
    * [<strong>Query</strong>](#query-19)
    * [<strong>Result</strong>](#result-19)
  * [<strong>Create Media</strong>](#create-media-3)
    * [<strong>Query</strong>](#query-20)
    * [<strong>Result</strong>](#result-20)
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-21)
    * [<strong>Result</strong>](#result-21)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-22)
    * [<strong>Result</strong>](#result-22)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Read Media</strong>](#read-media)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
  * [<strong>Read Media</strong>](#read-media-1)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Read Media</strong>](#read-media-2)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
* [Project](#project)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
* [Project Source](#project-source)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
* [Source](#source)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
  * [<strong>Get By Id Source</strong>](#get-by-id-source)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
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
  * [<strong>Destroy Tag</strong>](#destroy-tag)
    * [<strong>Query</strong>](#query-46)
    * [<strong>Result</strong>](#result-46)
  * [<strong>Create Tag</strong>](#create-tag)
    * [<strong>Query</strong>](#query-47)
    * [<strong>Result</strong>](#result-47)
  * [<strong>Read Tag</strong>](#read-tag)
    * [<strong>Query</strong>](#query-48)
    * [<strong>Result</strong>](#result-48)
* [Team](#team)
  * [<strong>Update Team</strong>](#update-team)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
  * [<strong>Destroy Team</strong>](#destroy-team)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-51)
    * [<strong>Result</strong>](#result-51)
  * [<strong>Read Collection Team</strong>](#read-collection-team)
    * [<strong>Query</strong>](#query-52)
    * [<strong>Result</strong>](#result-52)
  * [<strong>Read Team</strong>](#read-team)
    * [<strong>Query</strong>](#query-53)
    * [<strong>Result</strong>](#result-53)
  * [<strong>Get By Id Team</strong>](#get-by-id-team)
    * [<strong>Query</strong>](#query-54)
    * [<strong>Result</strong>](#result-54)
* [Team User](#team-user)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
* [User](#user)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Get By Id User</strong>](#get-by-id-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-63)
    * [<strong>Result</strong>](#result-63)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-64)
    * [<strong>Result</strong>](#result-64)

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
                      "url": "http://XHUIQYNXVJ.com"
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
        "id": "QWNjb3VudC82\n"
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
              "url": "http://UKCEQAVKZT.com"
            }
          },
          {
            "node": {
              "url": "http://XVZEEEXPCJ.com"
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
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC85
", user_id: 165 }) { account { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 165
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
                "name": "BJXBKYYZPM"
              },
              "source": {
                "name": "ZTOTNFQAGN"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "YRNRAQTIGL"
              },
              "source": {
                "name": "CHUPCULJFN"
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
              "context_id": "116"
            }
          },
          {
            "node": {
              "context_id": "117"
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmdsSFJxM1hqU3MteS12VmtBaw==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmdsSFJxM1hqU3MteS12VmtBaw==\n"
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
                "name": "TEGXEJAFCS"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "BXTFUBQQDX"
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

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "Project", annotated_id: "36", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVmdsSER2WVhqU3MteS12VmpfNg==\n"
      }
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmdsSEVVQ1hqU3MteS12VmpfNw==
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
              "text": "OLWLUKWZVXGQUZLJBYBEEYMKIZNCXFQCBUTQIBIOFSFQFCQGLS"
            }
          },
          {
            "node": {
              "text": "UDKGBARAKEISWGNWAZQVJJVSRIPXWYMXDZXBNLBSWLKXNEWHSZ"
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmdsSFVUcVhqU3MteS12VmtBcw==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmdsSFVUcVhqU3MteS12VmtBcw==\n"
    }
  }
}
```


## Contact

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
                "name": "YURDMSFBAK"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "LJPOECMMJX"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy Contact__

#### __Query__

```graphql
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC8z
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC8z\n"
    }
  }
}
```

### __Create Contact__

#### __Query__

```graphql
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 110, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC80\n"
      }
    }
  }
}
```

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC81
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
              "location": "SBTCWAMSDA"
            }
          },
          {
            "node": {
              "location": "YSNGNBNJCU"
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
mutation create { createMedia(input: {url: "http://SIOTGVHHLV.com", project_id: 46, clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvMw==\n"
      }
    }
  }
}
```

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "http://XQGTEOFRDO.com", project_id: 52, information: "{\"title\":\"title\",\"description\":\"description\",\"quote\":\"media quote\"}", clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvNQ==\n"
      }
    }
  }
}
```

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "", information: "{\"title\":\"title\",\"description\":\"description\",\"quote\":\"media quote\"}", clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvNg==\n"
      }
    }
  }
}
```

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {information: "{\"title\":\"title\",\"description\":\"description\",\"quote\":\"media quote\"}", clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvNw==\n"
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
                      "title": "JKDFOOCIOX"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"QGJGIGHQIODJOPFJMDHPZCSXQUGISWHNBEVYRIKRDOTZCQPPWY\"}"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "QGJGIGHQIODJOPFJMDHPZCSXQUGISWHNBEVYRIKRDOTZCQPPWY"
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
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMTU=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMTU=\n"
    }
  }
}
```

### __Read Object Media__

#### __Query__

```graphql
query read { root { medias { edges { node { account { url } } } } } }
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
                "url": "http://ZKAAYKCJNU.com"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://MNJHALVMPB.com"
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
              "url": "http://FAXMFRKWVN.com"
            }
          },
          {
            "node": {
              "url": "http://RDYFPYEXER.com"
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
              "published": null
            }
          },
          {
            "node": {
              "published": null
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
              "last_status": "undetermined"
            }
          },
          {
            "node": {
              "last_status": "undetermined"
            }
          }
        ]
      }
    }
  }
}
```


## Project

### __Update Project__

#### __Query__

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8zMg==
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
        "id": "UHJvamVjdC8zNA==\n"
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
              "title": "RUKLXPNOYH"
            }
          },
          {
            "node": {
              "title": "BDVPSMPNSH"
            }
          }
        ]
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
                "name": "MILYPJYSAO"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "ZGDTBBNOPY"
              }
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
                      "name": "RQAGYLPXHZ"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://TVHCKHJASK.com"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"VOQDYPCSKIAGTARPXQPEROTEJCETDMYLHJBNQVGHCGIHAEFWHW\"}"
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

### __Destroy Project__

#### __Query__

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8xNTI=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8xNTI=\n"
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
              "source_id": 121
            }
          },
          {
            "node": {
              "source_id": 123
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
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS84
", project_id: 72 }) { project_source { project_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "project_id": 72
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
                "title": "OYNAXPUEFL"
              },
              "source": {
                "name": "TVWIVELNWC"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "CSHGDPGPGW"
              },
              "source": {
                "name": "WZEIQQPJQK"
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
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8xOA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8xOA==\n"
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 401, project_id: 160, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS8xOQ==\n"
      }
    }
  }
}
```


## Source

### __Update Source__

#### __Query__

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzEwNg==
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
query GetById { source(id: "196") { name } }
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
                      "url": "http://BEDVYIHEKQ.com"
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
                      "title": "IHPGCRSHJW"
                    }
                  },
                  {
                    "node": {
                      "title": "BJXUVSUKDS"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://XUALHUWINL.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://VAUGQIRNFK.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 106
                    }
                  },
                  {
                    "node": {
                      "project_id": 107
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"VXCYLUCNLYEMXFALSMVOGWXAQXJHOSQXCHXDOPCJOGYKCWMLCW\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"OZQVDFZEZGFLMMUADDQQVONJFYNJZHOMTSXOCITCDJEAJWPMPG\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"QKTLWVOWKTDWWDZKMLOESFIVJBZYJRLDYAYBQWRQVKKPCUIVVD\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://KRDDZJYMBK.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "MXDRHZXSRZ"
                    }
                  },
                  {
                    "node": {
                      "name": "HTAURQWIRX"
                    }
                  },
                  {
                    "node": {
                      "name": "FILHUHEGBA"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "VXCYLUCNLYEMXFALSMVOGWXAQXJHOSQXCHXDOPCJOGYKCWMLCW"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "OZQVDFZEZGFLMMUADDQQVONJFYNJZHOMTSXOCITCDJEAJWPMPG"
                    }
                  },
                  {
                    "node": {
                      "text": "QKTLWVOWKTDWWDZKMLOESFIVJBZYJRLDYAYBQWRQVKKPCUIVVD"
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
        "id": "U291cmNlLzM1MQ==\n"
      }
    }
  }
}
```


## Status

### __Create Status__

#### __Query__

```graphql
mutation create { createStatus(input: {status: "credible", annotated_type: "Source", annotated_id: "148", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWZ2xISEVmWGpTcy15LXZWa0FM\n"
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
              "status": "credible"
            }
          },
          {
            "node": {
              "status": "credible"
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
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWZ2xIU21sWGpTcy15LXZWa0Fu
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWZ2xIU21sWGpTcy15LXZWa0Fu\n"
    }
  }
}
```


## Tag

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWZ2xISk9LWGpTcy15LXZWa0FP
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWZ2xISk9LWGpTcy15LXZWa0FP\n"
    }
  }
}
```

### __Create Tag__

#### __Query__

```graphql
mutation create { createTag(input: {tag: "egypt", annotated_type: "Media", annotated_id: "11", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWZ2xIUEpzWGpTcy15LXZWa0Fl\n"
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
              "tag": "SXRYVJHMBHYSSULBSXEADTOVNMMWPQRHMUNJCJXKHDABPNXBTE"
            }
          },
          {
            "node": {
              "tag": "TVZISQFRMDHCATJAHKUYMKUGFOOMFUWYAPXCNTEFUWKIRBNFYM"
            }
          }
        ]
      }
    }
  }
}
```


## Team

### __Update Team__

#### __Query__

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS80NA==
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

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS82OA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS82OA==\n"
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
        "id": "VGVhbS85NQ==\n"
      }
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
                      "user_id": 238
                    }
                  },
                  {
                    "node": {
                      "user_id": 239
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "YRKONOUYSF"
                    }
                  },
                  {
                    "node": {
                      "name": "JYWTLHEPOR"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "SUMOAJWGML"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "XKPBEOXRAX"
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
              "name": "NHYTSUUFQY"
            }
          },
          {
            "node": {
              "name": "ZVALBPIREK"
            }
          }
        ]
      }
    }
  }
}
```

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "150") { name } }
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
              "user_id": 119
            }
          },
          {
            "node": {
              "user_id": 120
            }
          },
          {
            "node": {
              "user_id": 118
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
                "name": "VSKADQSZRI"
              },
              "user": {
                "name": "OTQOYTTQKV"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "TKGXOOMJXF"
              },
              "user": {
                "name": "MDSOXLKCKH"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "RKRGIWWJKV"
              },
              "user": {
                "name": "LCKWUDKKBV"
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
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvNTU=
", team_id: 88 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 88
      }
    }
  }
}
```

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 96, user_id: 176, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvNjM=\n"
      }
    }
  }
}
```


## User

### __Update User__

#### __Query__

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci85Nw==
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
                      "name": "OKCKNJZAJW"
                    }
                  },
                  {
                    "node": {
                      "name": "HZAAGYTVJE"
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
              "email": "meypvxenbo@htktaploiq.com"
            }
          },
          {
            "node": {
              "email": "pqshnkmeoi@xeupsyxgya.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "217") { name } }
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
                "name": "FIPKOTLTBV"
              },
              "current_team": {
                "name": "ZWCMGBEHUP"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "WBLGHNQDGA"
              },
              "current_team": {
                "name": "ZWCMGBEHUP"
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
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8yNjU=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8yNjU=\n"
    }
  }
}
```

