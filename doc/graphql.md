# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

* [Account](#account)
  * [<strong>Update Account</strong>](#update-account)
    * [<strong>Query</strong>](#query)
    * [<strong>Result</strong>](#result)
  * [<strong>Read Collection Account</strong>](#read-collection-account)
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
  * [<strong>Create Comment</strong>](#create-comment)
    * [<strong>Query</strong>](#query-8)
    * [<strong>Result</strong>](#result-8)
  * [<strong>Update Comment</strong>](#update-comment)
    * [<strong>Query</strong>](#query-9)
    * [<strong>Result</strong>](#result-9)
  * [<strong>Destroy Comment</strong>](#destroy-comment)
    * [<strong>Query</strong>](#query-10)
    * [<strong>Result</strong>](#result-10)
  * [<strong>Read Comment</strong>](#read-comment)
    * [<strong>Query</strong>](#query-11)
    * [<strong>Result</strong>](#result-11)
* [Contact](#contact)
  * [<strong>Read Object Contact</strong>](#read-object-contact)
    * [<strong>Query</strong>](#query-12)
    * [<strong>Result</strong>](#result-12)
  * [<strong>Create Contact</strong>](#create-contact)
    * [<strong>Query</strong>](#query-13)
    * [<strong>Result</strong>](#result-13)
  * [<strong>Read Contact</strong>](#read-contact)
    * [<strong>Query</strong>](#query-14)
    * [<strong>Result</strong>](#result-14)
  * [<strong>Update Contact</strong>](#update-contact)
    * [<strong>Query</strong>](#query-15)
    * [<strong>Result</strong>](#result-15)
  * [<strong>Destroy Contact</strong>](#destroy-contact)
    * [<strong>Query</strong>](#query-16)
    * [<strong>Result</strong>](#result-16)
* [Media](#media)
  * [<strong>Destroy Media</strong>](#destroy-media)
    * [<strong>Query</strong>](#query-17)
    * [<strong>Result</strong>](#result-17)
  * [<strong>Create Media</strong>](#create-media)
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
  * [<strong>Read Collection Media</strong>](#read-collection-media)
    * [<strong>Query</strong>](#query-23)
    * [<strong>Result</strong>](#result-23)
  * [<strong>Read Object Media</strong>](#read-object-media)
    * [<strong>Query</strong>](#query-24)
    * [<strong>Result</strong>](#result-24)
* [Project](#project)
  * [<strong>Read Project</strong>](#read-project)
    * [<strong>Query</strong>](#query-25)
    * [<strong>Result</strong>](#result-25)
  * [<strong>Create Project</strong>](#create-project)
    * [<strong>Query</strong>](#query-26)
    * [<strong>Result</strong>](#result-26)
  * [<strong>Destroy Project</strong>](#destroy-project)
    * [<strong>Query</strong>](#query-27)
    * [<strong>Result</strong>](#result-27)
  * [<strong>Read Collection Project</strong>](#read-collection-project)
    * [<strong>Query</strong>](#query-28)
    * [<strong>Result</strong>](#result-28)
  * [<strong>Read Object Project</strong>](#read-object-project)
    * [<strong>Query</strong>](#query-29)
    * [<strong>Result</strong>](#result-29)
  * [<strong>Update Project</strong>](#update-project)
    * [<strong>Query</strong>](#query-30)
    * [<strong>Result</strong>](#result-30)
* [Project Source](#project-source)
  * [<strong>Read Object Project Source</strong>](#read-object-project-source)
    * [<strong>Query</strong>](#query-31)
    * [<strong>Result</strong>](#result-31)
  * [<strong>Read Project Source</strong>](#read-project-source)
    * [<strong>Query</strong>](#query-32)
    * [<strong>Result</strong>](#result-32)
  * [<strong>Destroy Project Source</strong>](#destroy-project-source)
    * [<strong>Query</strong>](#query-33)
    * [<strong>Result</strong>](#result-33)
  * [<strong>Update Project Source</strong>](#update-project-source)
    * [<strong>Query</strong>](#query-34)
    * [<strong>Result</strong>](#result-34)
  * [<strong>Create Project Source</strong>](#create-project-source)
    * [<strong>Query</strong>](#query-35)
    * [<strong>Result</strong>](#result-35)
* [Source](#source)
  * [<strong>Create Source</strong>](#create-source)
    * [<strong>Query</strong>](#query-36)
    * [<strong>Result</strong>](#result-36)
  * [<strong>Update Source</strong>](#update-source)
    * [<strong>Query</strong>](#query-37)
    * [<strong>Result</strong>](#result-37)
  * [<strong>Read Collection Source</strong>](#read-collection-source)
    * [<strong>Query</strong>](#query-38)
    * [<strong>Result</strong>](#result-38)
  * [<strong>Get By Id Source</strong>](#get-by-id-source)
    * [<strong>Query</strong>](#query-39)
    * [<strong>Result</strong>](#result-39)
  * [<strong>Read Source</strong>](#read-source)
    * [<strong>Query</strong>](#query-40)
    * [<strong>Result</strong>](#result-40)
* [Status](#status)
  * [<strong>Create Status</strong>](#create-status)
    * [<strong>Query</strong>](#query-41)
    * [<strong>Result</strong>](#result-41)
  * [<strong>Read Status</strong>](#read-status)
    * [<strong>Query</strong>](#query-42)
    * [<strong>Result</strong>](#result-42)
  * [<strong>Destroy Status</strong>](#destroy-status)
    * [<strong>Query</strong>](#query-43)
    * [<strong>Result</strong>](#result-43)
* [Tag](#tag)
  * [<strong>Read Tag</strong>](#read-tag)
    * [<strong>Query</strong>](#query-44)
    * [<strong>Result</strong>](#result-44)
  * [<strong>Create Tag</strong>](#create-tag)
    * [<strong>Query</strong>](#query-45)
    * [<strong>Result</strong>](#result-45)
  * [<strong>Destroy Tag</strong>](#destroy-tag)
    * [<strong>Query</strong>](#query-46)
    * [<strong>Result</strong>](#result-46)
* [Team](#team)
  * [<strong>Get By Id Team</strong>](#get-by-id-team)
    * [<strong>Query</strong>](#query-47)
    * [<strong>Result</strong>](#result-47)
  * [<strong>Read Collection Team</strong>](#read-collection-team)
    * [<strong>Query</strong>](#query-48)
    * [<strong>Result</strong>](#result-48)
  * [<strong>Destroy Team</strong>](#destroy-team)
    * [<strong>Query</strong>](#query-49)
    * [<strong>Result</strong>](#result-49)
  * [<strong>Create Team</strong>](#create-team)
    * [<strong>Query</strong>](#query-50)
    * [<strong>Result</strong>](#result-50)
  * [<strong>Read Team</strong>](#read-team)
    * [<strong>Query</strong>](#query-51)
    * [<strong>Result</strong>](#result-51)
  * [<strong>Update Team</strong>](#update-team)
    * [<strong>Query</strong>](#query-52)
    * [<strong>Result</strong>](#result-52)
* [Team User](#team-user)
  * [<strong>Read Team User</strong>](#read-team-user)
    * [<strong>Query</strong>](#query-53)
    * [<strong>Result</strong>](#result-53)
  * [<strong>Read Object Team User</strong>](#read-object-team-user)
    * [<strong>Query</strong>](#query-54)
    * [<strong>Result</strong>](#result-54)
  * [<strong>Update Team User</strong>](#update-team-user)
    * [<strong>Query</strong>](#query-55)
    * [<strong>Result</strong>](#result-55)
  * [<strong>Create Team User</strong>](#create-team-user)
    * [<strong>Query</strong>](#query-56)
    * [<strong>Result</strong>](#result-56)
* [User](#user)
  * [<strong>Update User</strong>](#update-user)
    * [<strong>Query</strong>](#query-57)
    * [<strong>Result</strong>](#result-57)
  * [<strong>Read Object User</strong>](#read-object-user)
    * [<strong>Query</strong>](#query-58)
    * [<strong>Result</strong>](#result-58)
  * [<strong>Destroy User</strong>](#destroy-user)
    * [<strong>Query</strong>](#query-59)
    * [<strong>Result</strong>](#result-59)
  * [<strong>Read User</strong>](#read-user)
    * [<strong>Query</strong>](#query-60)
    * [<strong>Result</strong>](#result-60)
  * [<strong>Read Collection User</strong>](#read-collection-user)
    * [<strong>Query</strong>](#query-61)
    * [<strong>Result</strong>](#result-61)
  * [<strong>Get By Id User</strong>](#get-by-id-user)
    * [<strong>Query</strong>](#query-62)
    * [<strong>Result</strong>](#result-62)

## Account

### __Update Account__

#### __Query__

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8xMzM3
", user_id: 12842 }) { account { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateAccount": {
      "account": {
        "user_id": 12842
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
                      "url": "http://KVHKXWJMVK.com"
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
                "name": "SHUFWKHYSX"
              },
              "source": {
                "name": "NJUWGOXINP"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "FDWVUHGFVS"
              },
              "source": {
                "name": "XLLWZKJWQN"
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
              "url": "http://GVRPGRDCEP.com"
            }
          },
          {
            "node": {
              "url": "http://QFOZTWJZRY.com"
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
        "id": "QWNjb3VudC8xMzYz\n"
      }
    }
  }
}
```


## Annotation

### __Destroy Annotation__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmZlaGoyLWthVldSSDBhMXRNZg==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmZlaGoyLWthVldSSDBhMXRNZg==\n"
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
              "context_id": "5613"
            }
          },
          {
            "node": {
              "context_id": "5614"
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
                "name": "SYWXKPZRHE"
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "QYOVAKNJEU"
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
mutation create { createComment(input: {text: "test", annotated_type: "Project", annotated_id: "5601", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVmZlaGtyUGthVldSSDBhMXRNZw==\n"
      }
    }
  }
}
```

### __Update Comment__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmZlaHVIS2thVldSSDBhMXROUg==
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVmZlaHp0dGthVldSSDBhMXROaQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVmZlaHp0dGthVldSSDBhMXROaQ==\n"
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
              "text": "MZMDTXDOXIIONRTQRZXNIWPFXZQOOXPKECMHXYOLCUZSZPPTRW"
            }
          },
          {
            "node": {
              "text": "MECJAQGTGOXQRRWFFTEIAUZGWVXQSKMCHXGXWLXWMLAKASNMJW"
            }
          }
        ]
      }
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
                "name": "APNKJCYOLQ"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "XTCZPSCEJX"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Create Contact__

#### __Query__

```graphql
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 6308, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC8xNzI=\n"
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
              "location": "IFGCZNKKGU"
            }
          },
          {
            "node": {
              "location": "QLSPUXYCCA"
            }
          }
        ]
      }
    }
  }
}
```

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC8xNzU=
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
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC8xNzY=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC8xNzY=\n"
    }
  }
}
```


## Media

### __Destroy Media__

#### __Query__

```graphql
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvOTg5
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvOTg5\n"
    }
  }
}
```

### __Create Media__

#### __Query__

```graphql
mutation create { createMedia(input: {url: "http://RJKUDVDOZZ.com", project_id: 5608, clientMutationId: "1"}) { media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createMedia": {
      "media": {
        "id": "TWVkaWEvOTkw\n"
      }
    }
  }
}
```

### __Update Media__

#### __Query__

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvOTkz
", user_id: 12940 }) { media { user_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateMedia": {
      "media": {
        "user_id": 12940
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
              "url": "http://GQUYEUPBWU.com"
            }
          },
          {
            "node": {
              "url": "http://NWVPWZKIWW.com"
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
              "published": "1476907151"
            }
          },
          {
            "node": {
              "published": "1476907152"
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
                      "title": "ZECPYQSJOB"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"JJXMCDTVHCURNVNOSVRYJYGAFDNPCPHVYJGVPEHYROKTAYSKJN\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"title\":null,\"description\":null,\"username\":null,\"published_at\":null,\"quote\":null,\"embed\":\"{\\\"url\\\":\\\"http://YKCIANRSSH.com\\\",\\\"type\\\":\\\"item\\\"}\"}"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "JJXMCDTVHCURNVNOSVRYJYGAFDNPCPHVYJGVPEHYROKTAYSKJN"
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
                "url": "http://TXMPBZIQUD.com"
              },
              "user": {
                "name": "SICZDTWNES"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://YVPRJJLDJZ.com"
              },
              "user": {
                "name": "TGOTPBRANC"
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
              "title": "BXDREJDUSS"
            }
          },
          {
            "node": {
              "title": "PMPDLFVLGT"
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
        "id": "UHJvamVjdC81NjE5\n"
      }
    }
  }
}
```

### __Destroy Project__

#### __Query__

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC81NjI4
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC81NjI4\n"
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
                      "name": "VGULGPUQXO"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://EZPADBNLMU.com"
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"BVOCHMUDUNZLHZHPUVCMIYZPNVEWZEFIQMLBZTBWNSWYOOXRUI\"}"
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
                "name": "UNVEYOHIIX"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "MBVHNYFCLT"
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
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC81Njc5
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
                "title": "WLPIUMBSYD"
              },
              "source": {
                "name": "FFHDSXHURF"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "VTOMTZLFSU"
              },
              "source": {
                "name": "HWHCCXIMCA"
              }
            }
          }
        ]
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
              "source_id": 16327
            }
          },
          {
            "node": {
              "source_id": 16329
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
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8yMzQ=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8yMzQ=\n"
    }
  }
}
```

### __Update Project Source__

#### __Query__

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8yNDE=
", project_id: 5682 }) { project_source { project_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateProjectSource": {
      "project_source": {
        "project_id": 5682
      }
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 16542, project_id: 5697, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS8yNDU=\n"
      }
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
        "id": "U291cmNlLzE2MjY4\n"
      }
    }
  }
}
```

### __Update Source__

#### __Query__

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzE2MzQ4
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
                      "url": "http://XXINCUIDHU.com"
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
                      "title": "CJPLRNSKYO"
                    }
                  },
                  {
                    "node": {
                      "title": "WVAIYRCJDT"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://MIKXKAIODH.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://TNPXBDOAZV.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 5674
                    }
                  },
                  {
                    "node": {
                      "project_id": 5675
                    }
                  }
                ]
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"tag\":\"HESQKJRWHVBCNVZOKNFFBLXMQOINRAGDNFAGJEGZDCUYMODCHF\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"SSGKQHJGUKIQBWMSMCOVBBIJRHLCDQIQADYTOLYZLMVFNETZRE\"}"
                    }
                  },
                  {
                    "node": {
                      "content": "{\"text\":\"KGFVEQXEGRFVMPXRPGGWIJKRXVGXOVXKYTSXNZVNCIGDQXDQOS\"}"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://CGGLRSJYRK.com"
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "NXUOANASDW"
                    }
                  },
                  {
                    "node": {
                      "name": "JPKUXUYSYM"
                    }
                  },
                  {
                    "node": {
                      "name": "KXCYURKRZC"
                    }
                  }
                ]
              },
              "tags": {
                "edges": [
                  {
                    "node": {
                      "tag": "HESQKJRWHVBCNVZOKNFFBLXMQOINRAGDNFAGJEGZDCUYMODCHF"
                    }
                  }
                ]
              },
              "comments": {
                "edges": [
                  {
                    "node": {
                      "text": "SSGKQHJGUKIQBWMSMCOVBBIJRHLCDQIQADYTOLYZLMVFNETZRE"
                    }
                  },
                  {
                    "node": {
                      "text": "KGFVEQXEGRFVMPXRPGGWIJKRXVGXOVXKYTSXNZVNCIGDQXDQOS"
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

### __Get By Id Source__

#### __Query__

```graphql
query GetById { source(id: "16513") { name } }
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


## Status

### __Create Status__

#### __Query__

```graphql
mutation create { createStatus(input: {status: "credible", annotated_type: "Source", annotated_id: "16374", clientMutationId: "1"}) { status { id } } }
```

#### __Result__

```json
{
  "data": {
    "createStatus": {
      "status": {
        "id": "U3RhdHVzL0FWZmVocHlTa2FWV1JIMGExdE0w\n"
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
mutation destroy { destroyStatus(input: { clientMutationId: "1", id: "U3RhdHVzL0FWZmVoMTBRa2FWV1JIMGExdE5s
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyStatus": {
      "deletedId": "U3RhdHVzL0FWZmVoMTBRa2FWV1JIMGExdE5s\n"
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
              "tag": "GHEHIIFLIBDUVZJREPPZETJENTCNNHKAWZVEYJGXTOMKQXTTET"
            }
          },
          {
            "node": {
              "tag": "LWRLRSAPWJMOGNHGFFBFTFMSQOJDNSMLWWPMGSCFBXHXSXOKSL"
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
mutation create { createTag(input: {tag: "egypt", annotated_type: "Source", annotated_id: "16432", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnL0FWZmVocmIxa2FWV1JIMGExdE5K\n"
      }
    }
  }
}
```

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnL0FWZmVoekUya2FWV1JIMGExdE5o
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnL0FWZmVoekUya2FWV1JIMGExdE5o\n"
    }
  }
}
```


## Team

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "6283") { name } }
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
                      "user_id": 12853
                    }
                  },
                  {
                    "node": {
                      "user_id": 12854
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "EHXFERYPWA"
                    }
                  },
                  {
                    "node": {
                      "name": "TXPFPGSHNU"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "GSHPIIXOHY"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "EJVRQOCMCL"
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

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS82Mjk2
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS82Mjk2\n"
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
        "id": "VGVhbS82MzIx\n"
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
              "name": "LYVILPHXQT"
            }
          },
          {
            "node": {
              "name": "HBJUIJNHYB"
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
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS82Mzc2
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
              "user_id": 12836
            }
          },
          {
            "node": {
              "user_id": 12837
            }
          },
          {
            "node": {
              "user_id": 12835
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
                "name": "JPQWCJWDMJ"
              },
              "user": {
                "name": "GHLPFWHPCD"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "JOYFYTBTCO"
              },
              "user": {
                "name": "BSVVGROYJB"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "EFVHBJCYRP"
              },
              "user": {
                "name": "HJQNPGZDEZ"
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
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMjEzMA==
", team_id: 6369 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 6369
      }
    }
  }
}
```

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 6380, user_id: 13104, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvMjE0MA==\n"
      }
    }
  }
}
```


## User

### __Update User__

#### __Query__

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8xMjgzMw==
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
                "name": "JEPOPLSHVM"
              },
              "current_team": {
                "name": "SHKINSBLRK"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "TSAFKDYGVC"
              },
              "current_team": {
                "name": "SHKINSBLRK"
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
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8xMzAyNA==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8xMzAyNA==\n"
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
              "email": "ahmclyjbsx@elhbwvefvv.com"
            }
          },
          {
            "node": {
              "email": "jnnflmftaj@sddkpifnev.com"
            }
          }
        ]
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
                      "name": "ZQRYRLRAEC"
                    }
                  },
                  {
                    "node": {
                      "name": "WGKCTDSFRR"
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

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "13108") { name } }
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

