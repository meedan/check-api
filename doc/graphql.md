# GraphQL Documentation

You can test the GraphQL endpoint by going to `/graphiql`. The available actions are:


Table of Contents
=================

    * [Account](#account)
      * [Read Collection](#read-collection)
        * [<strong>Query</strong>](#query)
        * [<strong>Result</strong>](#result)
      * [Read Object](#read-object)
        * [<strong>Query</strong>](#query-1)
        * [<strong>Result</strong>](#result-1)
      * [Update](#update)
        * [<strong>Query</strong>](#query-2)
        * [<strong>Result</strong>](#result-2)
      * [Create](#create)
        * [<strong>Query</strong>](#query-3)
        * [<strong>Result</strong>](#result-3)
      * [Read](#read)
        * [<strong>Query</strong>](#query-4)
        * [<strong>Result</strong>](#result-4)
      * [Destroy](#destroy)
        * [<strong>Query</strong>](#query-5)
        * [<strong>Result</strong>](#result-5)
    * [Api Key](#api-key)
      * [Update](#update-1)
        * [<strong>Query</strong>](#query-6)
        * [<strong>Result</strong>](#result-6)
      * [Destroy](#destroy-1)
        * [<strong>Query</strong>](#query-7)
        * [<strong>Result</strong>](#result-7)
      * [Read](#read-1)
        * [<strong>Query</strong>](#query-8)
        * [<strong>Result</strong>](#result-8)
      * [Create](#create-1)
        * [<strong>Query</strong>](#query-9)
        * [<strong>Result</strong>](#result-9)
    * [Comment](#comment)
      * [Create](#create-2)
        * [<strong>Query</strong>](#query-10)
        * [<strong>Result</strong>](#result-10)
      * [Read](#read-2)
        * [<strong>Query</strong>](#query-11)
        * [<strong>Result</strong>](#result-11)
      * [Destroy](#destroy-2)
        * [<strong>Query</strong>](#query-12)
        * [<strong>Result</strong>](#result-12)
      * [Update](#update-2)
        * [<strong>Query</strong>](#query-13)
        * [<strong>Result</strong>](#result-13)
    * [Media](#media)
      * [Read](#read-3)
        * [<strong>Query</strong>](#query-14)
        * [<strong>Result</strong>](#result-14)
      * [Create](#create-3)
        * [<strong>Query</strong>](#query-15)
        * [<strong>Result</strong>](#result-15)
      * [Update](#update-3)
        * [<strong>Query</strong>](#query-16)
        * [<strong>Result</strong>](#result-16)
      * [Read Collection](#read-collection-1)
        * [<strong>Query</strong>](#query-17)
        * [<strong>Result</strong>](#result-17)
      * [Destroy](#destroy-3)
        * [<strong>Query</strong>](#query-18)
        * [<strong>Result</strong>](#result-18)
      * [Read Object](#read-object-1)
        * [<strong>Query</strong>](#query-19)
        * [<strong>Result</strong>](#result-19)
    * [Project](#project)
      * [Update](#update-4)
        * [<strong>Query</strong>](#query-20)
        * [<strong>Result</strong>](#result-20)
      * [Create](#create-4)
        * [<strong>Query</strong>](#query-21)
        * [<strong>Result</strong>](#result-21)
      * [Read Collection](#read-collection-2)
        * [<strong>Query</strong>](#query-22)
        * [<strong>Result</strong>](#result-22)
      * [Read](#read-4)
        * [<strong>Query</strong>](#query-23)
        * [<strong>Result</strong>](#result-23)
      * [Read Object](#read-object-2)
        * [<strong>Query</strong>](#query-24)
        * [<strong>Result</strong>](#result-24)
      * [Destroy](#destroy-4)
        * [<strong>Query</strong>](#query-25)
        * [<strong>Result</strong>](#result-25)
    * [Project Source](#project-source)
      * [Destroy](#destroy-5)
        * [<strong>Query</strong>](#query-26)
        * [<strong>Result</strong>](#result-26)
      * [Update](#update-5)
        * [<strong>Query</strong>](#query-27)
        * [<strong>Result</strong>](#result-27)
      * [Create](#create-5)
        * [<strong>Query</strong>](#query-28)
        * [<strong>Result</strong>](#result-28)
      * [Read Object](#read-object-3)
        * [<strong>Query</strong>](#query-29)
        * [<strong>Result</strong>](#result-29)
      * [Read](#read-5)
        * [<strong>Query</strong>](#query-30)
        * [<strong>Result</strong>](#result-30)
    * [Source](#source)
      * [Destroy](#destroy-6)
        * [<strong>Query</strong>](#query-31)
        * [<strong>Result</strong>](#result-31)
      * [Read Collection](#read-collection-3)
        * [<strong>Query</strong>](#query-32)
        * [<strong>Result</strong>](#result-32)
      * [Create](#create-6)
        * [<strong>Query</strong>](#query-33)
        * [<strong>Result</strong>](#result-33)
      * [Update](#update-6)
        * [<strong>Query</strong>](#query-34)
        * [<strong>Result</strong>](#result-34)
      * [Read](#read-6)
        * [<strong>Query</strong>](#query-35)
        * [<strong>Result</strong>](#result-35)
    * [Team](#team)
      * [Update](#update-7)
        * [<strong>Query</strong>](#query-36)
        * [<strong>Result</strong>](#result-36)
      * [Read Collection](#read-collection-4)
        * [<strong>Query</strong>](#query-37)
        * [<strong>Result</strong>](#result-37)
      * [Read](#read-7)
        * [<strong>Query</strong>](#query-38)
        * [<strong>Result</strong>](#result-38)
      * [Destroy](#destroy-7)
        * [<strong>Query</strong>](#query-39)
        * [<strong>Result</strong>](#result-39)
      * [Create](#create-7)
        * [<strong>Query</strong>](#query-40)
        * [<strong>Result</strong>](#result-40)
    * [Team User](#team-user)
      * [Read Object](#read-object-4)
        * [<strong>Query</strong>](#query-41)
        * [<strong>Result</strong>](#result-41)
      * [Read](#read-8)
        * [<strong>Query</strong>](#query-42)
        * [<strong>Result</strong>](#result-42)
      * [Destroy](#destroy-8)
        * [<strong>Query</strong>](#query-43)
        * [<strong>Result</strong>](#result-43)
      * [Update](#update-8)
        * [<strong>Query</strong>](#query-44)
        * [<strong>Result</strong>](#result-44)
      * [Create](#create-8)
        * [<strong>Query</strong>](#query-45)
        * [<strong>Result</strong>](#result-45)
    * [User](#user)
      * [Create](#create-9)
        * [<strong>Query</strong>](#query-46)
        * [<strong>Result</strong>](#result-46)
      * [Read](#read-9)
        * [<strong>Query</strong>](#query-47)
        * [<strong>Result</strong>](#result-47)
      * [Update](#update-9)
        * [<strong>Query</strong>](#query-48)
        * [<strong>Result</strong>](#result-48)
      * [Destroy](#destroy-9)
        * [<strong>Query</strong>](#query-49)
        * [<strong>Result</strong>](#result-49)

Created by [gh-md-toc](https://github.com/ekalinin/github-markdown-toc)
## Account
### Read Collection 

#### **Query**

```graphql
query read { root { accounts { edges { node { medias { edges { node { url } } } } } } } }
```

#### **Result**

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
                      "url": "http://GBTARFFAYT.com"
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

### Read Object 

#### **Query**

```graphql
query read { root { accounts { edges { node { user { name }, source { name } } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "JBJOPVNNWZ"
              },
              "source": {
                "name": "COZJZWTUJB"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "IOGOPXJOHY"
              },
              "source": {
                "name": "MHHXKBQKZK"
              }
            }
          }
        ]
      }
    }
  }
}
```

### Update 

#### **Query**

```graphql
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 2 }) { account { user_id } } }
```

#### **Result**

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

### Create 

#### **Query**

```graphql
mutation create { createAccount(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { account { id } } }
```

#### **Result**

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

### Read 

#### **Query**

```graphql
query read { root { accounts { edges { node { url } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "url": "http://WVETUNWLCF.com"
            }
          },
          {
            "node": {
              "url": "http://KQKUCCDYGZ.com"
            }
          }
        ]
      }
    }
  }
}
```

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyAccount": {
      "deletedId": "QWNjb3VudC8x\n"
    }
  }
}
```

## Api Key
### Update 

#### **Query**

```graphql
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
", application: "bar" }) { api_key { application } } }
```

#### **Result**

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

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzE=
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzE=\n"
    }
  }
}
```

### Read 

#### **Query**

```graphql
query read { root { api_keys { edges { node { application } } } } }
```

#### **Result**

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

### Create 

#### **Query**

```graphql
mutation create { createApiKey(input: {application: "test", clientMutationId: "1"}) { api_key { id } } }
```

#### **Result**

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

## Comment
### Create 

#### **Query**

```graphql
mutation create { createComment(input: {text: "test", clientMutationId: "1"}) { comment { id } } }
```

#### **Result**

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVllUZ01oZjVjcG1wUlhNQXg4Tg==\n"
      }
    }
  }
}
```

### Read 

#### **Query**

```graphql
query read { root { comments { edges { node { text } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "comments": {
        "edges": [
          {
            "node": {
              "text": "EJMZOUDAWJXLHLLZJZBRBMQRNVLKTTMUSRPACEKVCLLMSDMNQT"
            }
          },
          {
            "node": {
              "text": "IJSXMTEYAJXVBJICHRUNSHWUFHUOFAJQSAHCDTGFNNVNQEBUQU"
            }
          }
        ]
      }
    }
  }
}
```

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUZ09IQjVjcG1wUlhNQXg4UQ==
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVllUZ09IQjVjcG1wUlhNQXg4UQ==\n"
    }
  }
}
```

### Update 

#### **Query**

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUZ08xZDVjcG1wUlhNQXg4Ug==
", text: "bar" }) { comment { text } } }
```

#### **Result**

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

## Media
### Read 

#### **Query**

```graphql
query read { root { medias { edges { node { url } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "url": "http://OGVHQIXQAL.com"
            }
          },
          {
            "node": {
              "url": "http://VMZUJMJBSZ.com"
            }
          }
        ]
      }
    }
  }
}
```

### Create 

#### **Query**

```graphql
mutation create { createMedia(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { media { id } } }
```

#### **Result**

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

### Update 

#### **Query**

```graphql
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 2 }) { media { user_id } } }
```

#### **Result**

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

### Read Collection 

#### **Query**

```graphql
query read { root { medias { edges { node { projects { edges { node { title } } } } } } } }
```

#### **Result**

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
                      "title": "DUQQFHVJYJ"
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

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMQ==\n"
    }
  }
}
```

### Read Object 

#### **Query**

```graphql
query read { root { medias { edges { node { account { url }, user { name } } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "account": {
                "url": "http://KJSNETFVYN.com"
              },
              "user": {
                "name": "JCOMYCLYOD"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://XKHOPBYZLP.com"
              },
              "user": {
                "name": "UPBPNUMWEW"
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
### Update 

#### **Query**

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
", title: "bar" }) { project { title } } }
```

#### **Result**

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

### Create 

#### **Query**

```graphql
mutation create { createProject(input: {title: "test", description: "test", clientMutationId: "1"}) { project { id } } }
```

#### **Result**

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

### Read Collection 

#### **Query**

```graphql
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

#### **Result**

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
                      "name": "RSOPIGVGDU"
                    }
                  },
                  {
                    "node": {
                      "name": "QAIRFHYEKC"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://WHAUKDSDWH.com"
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

### Read 

#### **Query**

```graphql
query read { root { projects { edges { node { title } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "title": "XJXJUWBEOR"
            }
          },
          {
            "node": {
              "title": "OLIBZAJYPY"
            }
          }
        ]
      }
    }
  }
}
```

### Read Object 

#### **Query**

```graphql
query read { root { projects { edges { node { user { name } } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "GIRPCLJMQS"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "MOGOGIQKMO"
              }
            }
          }
        ]
      }
    }
  }
}
```

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8x\n"
    }
  }
}
```

## Project Source
### Destroy 

#### **Query**

```graphql
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8x\n"
    }
  }
}
```

### Update 

#### **Query**

```graphql
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 2 }) { project_source { source_id } } }
```

#### **Result**

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

### Create 

#### **Query**

```graphql
mutation create { createProjectSource(input: {source_id: 1, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
```

#### **Result**

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

### Read Object 

#### **Query**

```graphql
query read { root { project_sources { edges { node { project { title }, source { name } } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "SIOYZDPGDQ"
              },
              "source": {
                "name": "EAKKFYYCOD"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "EGYRECMFWV"
              },
              "source": {
                "name": "PYRRVMPRJJ"
              }
            }
          }
        ]
      }
    }
  }
}
```

### Read 

#### **Query**

```graphql
query read { root { project_sources { edges { node { source_id } } } } }
```

#### **Result**

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

## Source
### Destroy 

#### **Query**

```graphql
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzI=
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzI=\n"
    }
  }
}
```

### Read Collection 

#### **Query**

```graphql
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

#### **Result**

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
                      "title": "MVTLIQJMLO"
                    }
                  },
                  {
                    "node": {
                      "title": "MOVIROCJPY"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://KOTRHTPZUU.com"
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

### Create 

#### **Query**

```graphql
mutation create { createSource(input: {name: "test", slogan: "test", clientMutationId: "1"}) { source { id } } }
```

#### **Result**

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

### Update 

#### **Query**

```graphql
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzI=
", name: "bar" }) { source { name } } }
```

#### **Result**

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

### Read 

#### **Query**

```graphql
query read { root { sources { edges { node { name } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "name": "LYXRECTBBV"
            }
          },
          {
            "node": {
              "name": "USVSKGALYH"
            }
          }
        ]
      }
    }
  }
}
```

## Team
### Update 

#### **Query**

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8x
", name: "bar" }) { team { name } } }
```

#### **Result**

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

### Read Collection 

#### **Query**

```graphql
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } } } } } } }
```

#### **Result**

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
                      "name": "NABHDROLWA"
                    }
                  },
                  {
                    "node": {
                      "name": "WAWNZSRMVL"
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

### Read 

#### **Query**

```graphql
query read { root { teams { edges { node { name } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "name": "UIOLFYGVAF"
            }
          },
          {
            "node": {
              "name": "KIMGMXBSDV"
            }
          }
        ]
      }
    }
  }
}
```

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8x
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8x\n"
    }
  }
}
```

### Create 

#### **Query**

```graphql
mutation create { createTeam(input: {name: "test", description: "test", clientMutationId: "1"}) { team { id } } }
```

#### **Result**

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
### Read Object 

#### **Query**

```graphql
query read { root { team_users { edges { node { team { name }, user { name } } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "JCHNBQDWRJ"
              },
              "user": {
                "name": "SNZYVBGDJT"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "XBJTTKNYXA"
              },
              "user": {
                "name": "FNTEZJPKEZ"
              }
            }
          }
        ]
      }
    }
  }
}
```

### Read 

#### **Query**

```graphql
query read { root { team_users { edges { node { user_id } } } } }
```

#### **Result**

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

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyTeamUser": {
      "deletedId": "VGVhbVVzZXIvMQ==\n"
    }
  }
}
```

### Update 

#### **Query**

```graphql
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
", team_id: 2 }) { team_user { team_id } } }
```

#### **Result**

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

### Create 

#### **Query**

```graphql
mutation create { createTeamUser(input: {team_id: 1, user_id: 1, clientMutationId: "1"}) { team_user { id } } }
```

#### **Result**

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
### Create 

#### **Query**

```graphql
mutation create { createUser(input: {email: "user@test.test", login: "test", name: "Test", password: "12345678", password_confirmation: "12345678", clientMutationId: "1"}) { user { id } } }
```

#### **Result**

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

### Read 

#### **Query**

```graphql
query read { root { users { edges { node { email } } } } }
```

#### **Result**

```json
{
  "data": {
    "root": {
      "users": {
        "edges": [
          {
            "node": {
              "email": "yuswrwqznw@agljcdrmvx.com"
            }
          },
          {
            "node": {
              "email": "yxmwuwluoe@slkqfootab.com"
            }
          }
        ]
      }
    }
  }
}
```

### Update 

#### **Query**

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8y
", name: "Bar" }) { user { name } } }
```

#### **Result**

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

### Destroy 

#### **Query**

```graphql
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8y
" }) { deletedId } }
```

#### **Result**

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8y\n"
    }
  }
}
```

