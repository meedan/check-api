# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

    * [Account](#account)
      * [<strong>Read Collection</strong>](#read-collection)
        * [<strong>Query</strong>](#query)
        * [<strong>Result</strong>](#result)
      * [<strong>Read Object</strong>](#read-object)
        * [<strong>Query</strong>](#query-1)
        * [<strong>Result</strong>](#result-1)
      * [<strong>Create</strong>](#create)
        * [<strong>Query</strong>](#query-2)
        * [<strong>Result</strong>](#result-2)
      * [<strong>Update</strong>](#update)
        * [<strong>Query</strong>](#query-3)
        * [<strong>Result</strong>](#result-3)
      * [<strong>Destroy</strong>](#destroy)
        * [<strong>Query</strong>](#query-4)
        * [<strong>Result</strong>](#result-4)
      * [<strong>Read</strong>](#read)
        * [<strong>Query</strong>](#query-5)
        * [<strong>Result</strong>](#result-5)
    * [Api Key](#api-key)
      * [<strong>Read</strong>](#read-1)
        * [<strong>Query</strong>](#query-6)
        * [<strong>Result</strong>](#result-6)
      * [<strong>Update</strong>](#update-1)
        * [<strong>Query</strong>](#query-7)
        * [<strong>Result</strong>](#result-7)
      * [<strong>Destroy</strong>](#destroy-1)
        * [<strong>Query</strong>](#query-8)
        * [<strong>Result</strong>](#result-8)
      * [<strong>Create</strong>](#create-1)
        * [<strong>Query</strong>](#query-9)
        * [<strong>Result</strong>](#result-9)
    * [Comment](#comment)
      * [<strong>Read</strong>](#read-2)
        * [<strong>Query</strong>](#query-10)
        * [<strong>Result</strong>](#result-10)
      * [<strong>Update</strong>](#update-2)
        * [<strong>Query</strong>](#query-11)
        * [<strong>Result</strong>](#result-11)
      * [<strong>Create</strong>](#create-2)
        * [<strong>Query</strong>](#query-12)
        * [<strong>Result</strong>](#result-12)
      * [<strong>Destroy</strong>](#destroy-2)
        * [<strong>Query</strong>](#query-13)
        * [<strong>Result</strong>](#result-13)
    * [Media](#media)
      * [<strong>Read Collection</strong>](#read-collection-1)
        * [<strong>Query</strong>](#query-14)
        * [<strong>Result</strong>](#result-14)
      * [<strong>Create</strong>](#create-3)
        * [<strong>Query</strong>](#query-15)
        * [<strong>Result</strong>](#result-15)
      * [<strong>Read</strong>](#read-3)
        * [<strong>Query</strong>](#query-16)
        * [<strong>Result</strong>](#result-16)
      * [<strong>Update</strong>](#update-3)
        * [<strong>Query</strong>](#query-17)
        * [<strong>Result</strong>](#result-17)
      * [<strong>Destroy</strong>](#destroy-3)
        * [<strong>Query</strong>](#query-18)
        * [<strong>Result</strong>](#result-18)
      * [<strong>Read Object</strong>](#read-object-1)
        * [<strong>Query</strong>](#query-19)
        * [<strong>Result</strong>](#result-19)
    * [Project](#project)
      * [<strong>Read Object</strong>](#read-object-2)
        * [<strong>Query</strong>](#query-20)
        * [<strong>Result</strong>](#result-20)
      * [<strong>Read Collection</strong>](#read-collection-2)
        * [<strong>Query</strong>](#query-21)
        * [<strong>Result</strong>](#result-21)
      * [<strong>Read</strong>](#read-4)
        * [<strong>Query</strong>](#query-22)
        * [<strong>Result</strong>](#result-22)
      * [<strong>Destroy</strong>](#destroy-4)
        * [<strong>Query</strong>](#query-23)
        * [<strong>Result</strong>](#result-23)
      * [<strong>Create</strong>](#create-4)
        * [<strong>Query</strong>](#query-24)
        * [<strong>Result</strong>](#result-24)
      * [<strong>Update</strong>](#update-4)
        * [<strong>Query</strong>](#query-25)
        * [<strong>Result</strong>](#result-25)
    * [Project Source](#project-source)
      * [<strong>Read Object</strong>](#read-object-3)
        * [<strong>Query</strong>](#query-26)
        * [<strong>Result</strong>](#result-26)
      * [<strong>Update</strong>](#update-5)
        * [<strong>Query</strong>](#query-27)
        * [<strong>Result</strong>](#result-27)
      * [<strong>Destroy</strong>](#destroy-5)
        * [<strong>Query</strong>](#query-28)
        * [<strong>Result</strong>](#result-28)
      * [<strong>Create</strong>](#create-5)
        * [<strong>Query</strong>](#query-29)
        * [<strong>Result</strong>](#result-29)
      * [<strong>Read</strong>](#read-5)
        * [<strong>Query</strong>](#query-30)
        * [<strong>Result</strong>](#result-30)
    * [Source](#source)
      * [<strong>Read</strong>](#read-6)
        * [<strong>Query</strong>](#query-31)
        * [<strong>Result</strong>](#result-31)
      * [<strong>Destroy</strong>](#destroy-6)
        * [<strong>Query</strong>](#query-32)
        * [<strong>Result</strong>](#result-32)
      * [<strong>Read Collection</strong>](#read-collection-3)
        * [<strong>Query</strong>](#query-33)
        * [<strong>Result</strong>](#result-33)
      * [<strong>Create</strong>](#create-6)
        * [<strong>Query</strong>](#query-34)
        * [<strong>Result</strong>](#result-34)
      * [<strong>Update</strong>](#update-6)
        * [<strong>Query</strong>](#query-35)
        * [<strong>Result</strong>](#result-35)
    * [Team](#team)
      * [<strong>Create</strong>](#create-7)
        * [<strong>Query</strong>](#query-36)
        * [<strong>Result</strong>](#result-36)
      * [<strong>Destroy</strong>](#destroy-7)
        * [<strong>Query</strong>](#query-37)
        * [<strong>Result</strong>](#result-37)
      * [<strong>Read</strong>](#read-7)
        * [<strong>Query</strong>](#query-38)
        * [<strong>Result</strong>](#result-38)
      * [<strong>Update</strong>](#update-7)
        * [<strong>Query</strong>](#query-39)
        * [<strong>Result</strong>](#result-39)
      * [<strong>Read Collection</strong>](#read-collection-4)
        * [<strong>Query</strong>](#query-40)
        * [<strong>Result</strong>](#result-40)
    * [Team User](#team-user)
      * [<strong>Create</strong>](#create-8)
        * [<strong>Query</strong>](#query-41)
        * [<strong>Result</strong>](#result-41)
      * [<strong>Read Object</strong>](#read-object-4)
        * [<strong>Query</strong>](#query-42)
        * [<strong>Result</strong>](#result-42)
      * [<strong>Destroy</strong>](#destroy-8)
        * [<strong>Query</strong>](#query-43)
        * [<strong>Result</strong>](#result-43)
      * [<strong>Update</strong>](#update-8)
        * [<strong>Query</strong>](#query-44)
        * [<strong>Result</strong>](#result-44)
      * [<strong>Read</strong>](#read-8)
        * [<strong>Query</strong>](#query-45)
        * [<strong>Result</strong>](#result-45)
    * [User](#user)
      * [<strong>Update</strong>](#update-9)
        * [<strong>Query</strong>](#query-46)
        * [<strong>Result</strong>](#result-46)
      * [<strong>Read</strong>](#read-9)
        * [<strong>Query</strong>](#query-47)
        * [<strong>Result</strong>](#result-47)
      * [<strong>Destroy</strong>](#destroy-9)
        * [<strong>Query</strong>](#query-48)
        * [<strong>Result</strong>](#result-48)
      * [<strong>Create</strong>](#create-9)
        * [<strong>Query</strong>](#query-49)
        * [<strong>Result</strong>](#result-49)
## Account
### __Read Collection__

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
                      "url": "http://KOBSLGECBG.com"
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

### __Read Object__

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
                "name": "RXXKJPSHTA"
              },
              "source": {
                "name": "SOTYXFAJDJ"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "GZJTRBJQFC"
              },
              "source": {
                "name": "CXKFPTTWDW"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Create__

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

### __Update__

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

### __Destroy__

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

### __Read__

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
              "url": "http://TGPSGSOGHO.com"
            }
          },
          {
            "node": {
              "url": "http://FOTOFLWTBD.com"
            }
          }
        ]
      }
    }
  }
}
```

## Api Key
### __Read__

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

### __Update__

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

### __Destroy__

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

### __Create__

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

## Comment
### __Read__

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
              "text": "JDMEBFBYIFDBYIKQETVQKITFDAGAQPIZLPVUSRUSTSUYOJZMJB"
            }
          },
          {
            "node": {
              "text": "XXCLCPXMWIATYVLCAEMNXXNWGBALVDUOWGPAKNGCVSQXGZRHAE"
            }
          }
        ]
      }
    }
  }
}
```

### __Update__

#### __Query__

```graphql
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUaHhOVDVjcG1wUlhNQXg4Wg==
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

### __Create__

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
        "id": "Q29tbWVudC9BVllUaHh6bzVjcG1wUlhNQXg4YQ==\n"
      }
    }
  }
}
```

### __Destroy__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVllUaHlFdTVjcG1wUlhNQXg4Yg==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVllUaHlFdTVjcG1wUlhNQXg4Yg==\n"
    }
  }
}
```

## Media
### __Read Collection__

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
                      "title": "LXXXNTYUWJ"
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

### __Create__

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

### __Read__

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
              "url": "http://YZZRUZZQDA.com"
            }
          },
          {
            "node": {
              "url": "http://TGEBYZPALP.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Update__

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

### __Destroy__

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

### __Read Object__

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
                "url": "http://VNYRMVRUII.com"
              },
              "user": {
                "name": "MJYQEDWTZC"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://IPDLFOVPND.com"
              },
              "user": {
                "name": "KWNBPPMPAH"
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
### __Read Object__

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
                "name": "GNAJYJWMWO"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "XSEYKNYBEB"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Read Collection__

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
                      "name": "UCMDWLGMUP"
                    }
                  },
                  {
                    "node": {
                      "name": "EEJPJYSCWU"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "http://ODYNONEHWX.com"
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

### __Read__

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
              "title": "VOXULZEFTX"
            }
          },
          {
            "node": {
              "title": "SCUAJEHGTB"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy__

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

### __Create__

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

### __Update__

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

## Project Source
### __Read Object__

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
                "title": "GMPEDBRLLC"
              },
              "source": {
                "name": "VHXZIJNCGX"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "CUBQIVPIVH"
              },
              "source": {
                "name": "RNCEKPTEKC"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Update__

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

### __Destroy__

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

### __Create__

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

### __Read__

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

## Source
### __Read__

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
              "name": "IYUYYFZDPN"
            }
          },
          {
            "node": {
              "name": "VXSZDCIFZK"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy__

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

### __Read Collection__

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
                      "title": "TRFXNVPNPZ"
                    }
                  },
                  {
                    "node": {
                      "title": "JBFOVQGVYE"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://KIFQXVIXEV.com"
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

### __Create__

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

### __Update__

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

## Team
### __Create__

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

### __Destroy__

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

### __Read__

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
              "name": "DLYOWKNJIM"
            }
          },
          {
            "node": {
              "name": "SCTOEAQNDK"
            }
          }
        ]
      }
    }
  }
}
```

### __Update__

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

### __Read Collection__

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
                      "name": "JSLWUEELYL"
                    }
                  },
                  {
                    "node": {
                      "name": "RYCRKECZNX"
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
### __Create__

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

### __Read Object__

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
                "name": "BCSNMGICMI"
              },
              "user": {
                "name": "UWIVNYDYZL"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "UZOCDTJCWS"
              },
              "user": {
                "name": "NPRFCTLNNJ"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy__

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

### __Update__

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

### __Read__

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

## User
### __Update__

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

### __Read__

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
              "email": "kgixygfqhe@njjvwnbpjc.com"
            }
          },
          {
            "node": {
              "email": "xyxjbdpclq@hkwidupmxd.com"
            }
          }
        ]
      }
    }
  }
}
```

### __Destroy__

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

### __Create__

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

