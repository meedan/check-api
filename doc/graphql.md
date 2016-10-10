# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Read Object Account</strong>](#read-object-account)
    * [<strong>Query</strong>](#query)
    * [<strong>Result</strong>](#result)
  * [<strong>Read Account</strong>](#read-account)
    * [<strong>Query</strong>](#query-1)
    * [<strong>Result</strong>](#result-1)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
    * [<strong>Query</strong>](#query-2)
    * [<strong>Result</strong>](#result-2)
  * [<strong>Create Account</strong>](#create-account)
    * [<strong>Query</strong>](#query-3)
    * [<strong>Result</strong>](#result-3)
  * [<strong>Update Account</strong>](#update-account)
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
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
* [Contact](#contact)
  * [<strong>Create Contact</strong>](#create-contact)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
  * [<strong>Update Contact</strong>](#update-contact)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Destroy Contact</strong>](#destroy-contact)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Read Contact</strong>](#read-contact)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Read Object Contact</strong>](#read-object-contact)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Media](#media)
  * [<strong>Create Media</strong>](#create-media)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-18)
    * [<strong>Result</strong>](#result-18)
  * [<strong>Update Media</strong>](#update-media)
    * [<strong>Query</strong>](#query-19)
    * [<strong>Result</strong>](#result-19)
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-20)
    * [<strong>Result</strong>](#result-20)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-21)
    * [<strong>Result</strong>](#result-21)
  * [<strong>Get By Id Media</strong>](#get-by-id-media)
    * [<strong>Query</strong>](#query-22)
    * [<strong>Result</strong>](#result-22)
  * [<strong>Read Media</strong>](#read-media)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Read Media</strong>](#read-media-1)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
  * [<strong>Read Media</strong>](#read-media-2)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Read Media</strong>](#read-media-3)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
* [Project](#project)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
* [Project Source](#project-source)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
* [Source](#source)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
  * [<strong>Get By Id Source</strong>](#get-by-id-source)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
  * [<strong>Create Source</strong>](#create-source)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
    * [<strong>Query</strong>](#query-41)
    * [<strong>Result</strong>](#result-41)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-42)
    * [<strong>Result</strong>](#result-42)
* [Status](#status)
  * [<strong>Destroy Status</strong>](#destroy-status)
    * [<strong>Query</strong>](#query-43)
    * [<strong>Result</strong>](#result-43)
  * [<strong>Create Status</strong>](#create-status)
    * [<strong>Query</strong>](#query-44)
    * [<strong>Result</strong>](#result-44)
  * [<strong>Read Status</strong>](#read-status)
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
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
  * [<strong>Get By Id Team</strong>](#get-by-id-team)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Update Team</strong>](#update-team)
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
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
* [User](#user)
  * [<strong>Get By Id User</strong>](#get-by-id-user)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-63)
    * [<strong>Result</strong>](#result-63)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-64)
    * [<strong>Result</strong>](#result-64)

## Account

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
                "name": "WSLZFRMOYX"
              },
              "source": {
                "name": "CGDJOVAJWT"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "JIKJXEIEQD"
              },
              "source": {
                "name": "BGVOYSDLFV"
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
              "url": "http://NZXZNLDGNL.com"
            }
          },
          {
            "node": {
              "url": "http://EAOEXTZTLQ.com"
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
                      "url": "http://JUJFWNOHFR.com"
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
        "id": "QWNjb3VudC8yNzk=\n"
      }
    }
  }
}
```

### __Update Account__

#### __Query__

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8yODg=
", user_id: 2285 }) { account { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 2285
      }
    }
  }
}
```


## Annotation

### __Destroy Annotation__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmV1VmU2TEhTMDQ5NmFMQUowdA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmV1VmU2TEhTMDQ5NmFMQUowdA==\n"
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
              "context_id": "874"
            }
          },
          {
            "node": {
              "context_id": "875"
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
                "name": "KORLWWXHMQ"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "TLEGKXKGEM"
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

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmV1Vm1FOUhTMDQ5NmFMQUowMw==
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmV1Vm05cUhTMDQ5NmFMQUowNA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmV1Vm05cUhTMDQ5NmFMQUowNA==\n"
    }
  }
}
```

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "Project", annotated_id: "955", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVmV1VnI0WkhTMDQ5NmFMQUowOQ==\n"
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
              "text": "IEOUEAQQCFMULZIQCTAXYLKTPNLNSICOAKZSSUPWGWMNLLFHBW"
            }
          },
          {
            "node": {
              "text": "LCHPQQHGDIMTELIYRNFTKLTFDTMNHEXKMLXVVEKRHRVFXOXYBN"
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
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 969, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC8yNQ==\n"
      }
    }
  }
}
```

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC8yNg==
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

### __Destroy Contact__

#### __Query__

```graphql
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC8yOA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC8yOA==\n"
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
              "location": "WCEVVYNWPK"
            }
          },
          {
            "node": {
              "location": "GBZIOJDQNK"
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
                "name": "IOEWQCPPJD"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "MBMKGDZSFE"
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

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "http://HGSIUJULWY.com", project_id: 847, clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvMjA1\n"
      }
    }
  }
}
```

### __Destroy Media__

#### __Query__

```graphql
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMjA2
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMjA2\n"
    }
  }
}
```

### __Update Media__

#### __Query__

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMjA4
", user_id: 2119 }) { media { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateMedia": {
      "media": {
        "user_id": 2119
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
                      "title": "LSFPDWWCWW"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"PXBNTKQBTGVAOQLKRVENXYQJKBZQVJVLIFUJJECLEZRDGFCYJM\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"LOKKCYSJRJDTIJTNBYWHHVKOTWVICSJEFYHGVPKJEXPKKBVHVZ\"}"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "PXBNTKQBTGVAOQLKRVENXYQJKBZQVJVLIFUJJECLEZRDGFCYJM"
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
                "url": "http://NRSUOCMDLX.com"
              },
              "user": {
                "name": "TRNUNXCNPN"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://CXECCJRUWB.com"
              },
              "user": {
                "name": "WDQXLHTXHN"
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
query GetById { media(id: "213") { user_id } }
```

#### __Result__

```json
{
  "data": {
    "media": {
      "user_id": 2218
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
              "url": "http://UQHXWOQQXM.com"
            }
          },
          {
            "node": {
              "url": "http://EXMDFZPPCU.com"
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
              "jsondata": "{\"url\":\"http://VPZVFBQPSH.com\",\"type\":\"item\"}"
            }
          },
          {
            "node": {
              "jsondata": "{\"url\":\"http://YDPYWGRGPP.com\",\"type\":\"item\"}"
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
              "published": "1476098701"
            }
          },
          {
            "node": {
              "published": "1476098701"
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


## Project

### __Update Project__

#### __Query__

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC84NTA=
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
                      "name": "YWFFILPPAD"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://BJLCXGCAVQ.com"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"TYOIDIMAIWUGRBWELQOWWBIGBXZDIWXENSEZTAIBKVYNXGICTB\"}"
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
        "id": "UHJvamVjdC84ODQ=\n"
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
              "title": "DSLGKZXEZI"
            }
          },
          {
            "node": {
              "title": "BRBMXEOXOP"
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
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC85MjM=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC85MjM=\n"
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
                "name": "URIEJVZFIC"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "CMSMMQRCZY"
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
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8zNA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8zNA==\n"
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 2678, project_id: 886, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS8zOQ==\n"
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
                "title": "AFWVOUVBTO"
              },
              "source": {
                "name": "UKWJSYGECI"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "PDGOMELRZB"
              },
              "source": {
                "name": "ALLNACLVMB"
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
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS80NQ==
", project_id: 931 }) { project_source { project_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "project_id": 931
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
              "source_id": 2864
            }
          },
          {
            "node": {
              "source_id": 2866
            }
          }
        ]
      }
    }
  }
}
```


## Source

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
query GetById { source(id: "2718") { name } }
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
        "id": "U291cmNlLzI3NTU=\n"
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
                      "url": "http://SJHTPCWGAS.com"
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
                      "title": "JPJPKYYPSP"
                    }
                  },
                  {
                    "node": {
                      "title": "DMSTMYGFJD"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://CALUEFLVFM.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://XSVBYKCIHJ.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 969
                    }
                  },
                  {
                    "node": {
                      "project_id": 970
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"MBYSKAMQRIWZWQDRNDNHIVXODRBEMNADDNBZDEOEBSOIHMYDQH\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"PWVYROAUPMDFXUMURQUKAAIGXQUQNHQZJHZKETIWSULWULBGFD\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"DBKMQZQILABZSKQATGOMRKXPOZRJEDNYAKQKDMNNDGYSNCTRPP\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://CSZCKYQUJI.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "SRTEMNBSBO"
                    }
                  },
                  {
                    "node": {
                      "name": "XAZBTTTMDX"
                    }
                  },
                  {
                    "node": {
                      "name": "MLMMCWBPQA"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "MBYSKAMQRIWZWQDRNDNHIVXODRBEMNADDNBZDEOEBSOIHMYDQH"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "PWVYROAUPMDFXUMURQUKAAIGXQUQNHQZJHZKETIWSULWULBGFD"
                    }
                  },
                  {
                    "node": {
                      "text": "DBKMQZQILABZSKQATGOMRKXPOZRJEDNYAKQKDMNNDGYSNCTRPP"
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
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzI5MjU=
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


## Status

### __Destroy Status__

#### __Query__

```graphql
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWZXVWZ3BWSFMwNDk2YUxBSjB2
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWZXVWZ3BWSFMwNDk2YUxBSjB2\n"
    }
  }
}
```

### __Create Status__

#### __Query__

```graphql
mutation create { createStatus(input: {status: "Credible", annotated_type: "Source", annotated_id: "2658", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWZXVWakZYSFMwNDk2YUxBSjB6\n"
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

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWZXVWZnVISFMwNDk2YUxBSjB1
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWZXVWZnVISFMwNDk2YUxBSjB1\n"
    }
  }
}
```

### __Create Tag__

#### __Query__

```graphql
mutation create { createTag(input: {tag: "egypt", annotated_type: "Source", annotated_id: "2655", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWZXVWaXRFSFMwNDk2YUxBSjB5\n"
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
              "tag": "ADRSCBJZYZFHHGJKQYCDVRQWAKUKLZOHIKPRFMSYKWWNSXRSML"
            }
          },
          {
            "node": {
              "tag": "ZOACZTPQBKWOBIQPQBKSPPCTDGGSZGPSWNENVXJZWMUKWKJMAC"
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
mutation create { createTeam(input: {name: "test", description: "test", subdomain: "test", clientMutationId: "1"}) { team { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeam": {
      "team": {
        "id": "VGVhbS85NTQ=\n"
      }
    }
  }
}
```

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "966") { name } }
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

### __Update Team__

#### __Query__

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS85ODI=
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
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS85ODk=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS85ODk=\n"
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
                      "user_id": 2164
                    }
                  },
                  {
                    "node": {
                      "user_id": 2165
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "XCWONDGMDR"
                    }
                  },
                  {
                    "node": {
                      "name": "LRDLCCWYCQ"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "NWVXBFWXXM"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "DXEEWNOAOP"
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
              "name": "VLVXTFFIJZ"
            }
          },
          {
            "node": {
              "name": "NUZABMLHFF"
            }
          }
        ]
      }
    }
  }
}
```


## Team User

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
                "name": "UBCVJZKPFE"
              },
              "user": {
                "name": "HPOKHUTTQV"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "DOCYVGZGGN"
              },
              "user": {
                "name": "NGRETGSJQF"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "TGMBEILNMO"
              },
              "user": {
                "name": "XXTLGDHBHM"
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
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMzYy
", team_id: 992 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 992
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
              "user_id": 2205
            }
          },
          {
            "node": {
              "user_id": 2206
            }
          },
          {
            "node": {
              "user_id": 2204
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
mutation create { createTeamUser(input: {team_id: 1031, user_id: 2235, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvMzk3\n"
      }
    }
  }
}
```


## User

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "2041") { name } }
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
                      "name": "WATIIVZFLJ"
                    }
                  },
                  {
                    "node": {
                      "name": "ZLYGKYYEOC"
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
                "name": "VDVIRBMDQP"
              },
              "current_team": {
                "name": "BDJSIVGIOF"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "AJMKODMYBV"
              },
              "current_team": {
                "name": "BDJSIVGIOF"
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
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8yMTQ2
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8yMTQ2\n"
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
              "email": "xckqaohdhx@pemducznny.com"
            }
          },
          {
            "node": {
              "email": "gvhgkwnuga@egwcnofqlv.com"
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
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8yMjI5
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

