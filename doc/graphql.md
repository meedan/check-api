# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

  * [Account](#account)
     * [<strong>Read Account</strong>](#read-account)
        * [<strong>Query</strong>](#query)
        * [<strong>Result</strong>](#result)
     * [<strong>Read Account</strong>](#read-account-1)
        * [<strong>Query</strong>](#query-1)
        * [<strong>Result</strong>](#result-1)
     * [<strong>Read Collection Account</strong>](#read-collection-account)
        * [<strong>Query</strong>](#query-2)
        * [<strong>Result</strong>](#result-2)
     * [<strong>Read Object Account</strong>](#read-object-account)
        * [<strong>Query</strong>](#query-3)
        * [<strong>Result</strong>](#result-3)
  * [Account Source](#account-source)
     * [<strong>Create Account Source</strong>](#create-account-source)
        * [<strong>Query</strong>](#query-4)
        * [<strong>Result</strong>](#result-4)
     * [<strong>Create Account Source</strong>](#create-account-source-1)
        * [<strong>Query</strong>](#query-5)
        * [<strong>Result</strong>](#result-5)
     * [<strong>Read Account Source</strong>](#read-account-source)
        * [<strong>Query</strong>](#query-6)
        * [<strong>Result</strong>](#result-6)
  * [Annotation](#annotation)
     * [<strong>Destroy Annotation</strong>](#destroy-annotation)
        * [<strong>Query</strong>](#query-7)
        * [<strong>Result</strong>](#result-7)
     * [<strong>Read Annotation</strong>](#read-annotation)
        * [<strong>Query</strong>](#query-8)
        * [<strong>Result</strong>](#result-8)
     * [<strong>Read Object Annotation</strong>](#read-object-annotation)
        * [<strong>Query</strong>](#query-9)
        * [<strong>Result</strong>](#result-9)
  * [Comment](#comment)
     * [<strong>Create Comment</strong>](#create-comment)
        * [<strong>Query</strong>](#query-10)
        * [<strong>Result</strong>](#result-10)
     * [<strong>Destroy Comment</strong>](#destroy-comment)
        * [<strong>Query</strong>](#query-11)
        * [<strong>Result</strong>](#result-11)
     * [<strong>Read Comment</strong>](#read-comment)
        * [<strong>Query</strong>](#query-12)
        * [<strong>Result</strong>](#result-12)
  * [Contact](#contact)
     * [<strong>Create Contact</strong>](#create-contact)
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
     * [<strong>Update Contact</strong>](#update-contact)
        * [<strong>Query</strong>](#query-17)
        * [<strong>Result</strong>](#result-17)
  * [Dynamic](#dynamic)
     * [<strong>Create Dynamic</strong>](#create-dynamic)
        * [<strong>Query</strong>](#query-18)
        * [<strong>Result</strong>](#result-18)
  * [Media](#media)
     * [<strong>Read Object Media</strong>](#read-object-media)
        * [<strong>Query</strong>](#query-19)
        * [<strong>Result</strong>](#result-19)
  * [Project](#project)
     * [<strong>Create Project</strong>](#create-project)
        * [<strong>Query</strong>](#query-20)
        * [<strong>Result</strong>](#result-20)
     * [<strong>Destroy Project</strong>](#destroy-project)
        * [<strong>Query</strong>](#query-21)
        * [<strong>Result</strong>](#result-21)
     * [<strong>Read Collection Project</strong>](#read-collection-project)
        * [<strong>Query</strong>](#query-22)
        * [<strong>Result</strong>](#result-22)
     * [<strong>Read Object Project</strong>](#read-object-project)
        * [<strong>Query</strong>](#query-23)
        * [<strong>Result</strong>](#result-23)
     * [<strong>Read Project</strong>](#read-project)
        * [<strong>Query</strong>](#query-24)
        * [<strong>Result</strong>](#result-24)
     * [<strong>Update Project</strong>](#update-project)
        * [<strong>Query</strong>](#query-25)
        * [<strong>Result</strong>](#result-25)
  * [Project Media](#project-media)
     * [<strong>Create Project Media</strong>](#create-project-media)
        * [<strong>Query</strong>](#query-26)
        * [<strong>Result</strong>](#result-26)
     * [<strong>Create Project Media</strong>](#create-project-media-1)
        * [<strong>Query</strong>](#query-27)
        * [<strong>Result</strong>](#result-27)
     * [<strong>Create Project Media</strong>](#create-project-media-2)
        * [<strong>Query</strong>](#query-28)
        * [<strong>Result</strong>](#result-28)
     * [<strong>Read Object Project Media</strong>](#read-object-project-media)
        * [<strong>Query</strong>](#query-29)
        * [<strong>Result</strong>](#result-29)
     * [<strong>Read Project Media</strong>](#read-project-media)
        * [<strong>Query</strong>](#query-30)
        * [<strong>Result</strong>](#result-30)
  * [Project Source](#project-source)
     * [<strong>Create Project Source</strong>](#create-project-source)
        * [<strong>Query</strong>](#query-31)
        * [<strong>Result</strong>](#result-31)
     * [<strong>Create Project Source</strong>](#create-project-source-1)
        * [<strong>Query</strong>](#query-32)
        * [<strong>Result</strong>](#result-32)
     * [<strong>Destroy Project Source</strong>](#destroy-project-source)
        * [<strong>Query</strong>](#query-33)
        * [<strong>Result</strong>](#result-33)
     * [<strong>Read Object Project Source</strong>](#read-object-project-source)
        * [<strong>Query</strong>](#query-34)
        * [<strong>Result</strong>](#result-34)
     * [<strong>Read Project Source</strong>](#read-project-source)
        * [<strong>Query</strong>](#query-35)
        * [<strong>Result</strong>](#result-35)
  * [Source](#source)
     * [<strong>Create Source</strong>](#create-source)
        * [<strong>Query</strong>](#query-36)
        * [<strong>Result</strong>](#result-36)
     * [<strong>Get By Id Source</strong>](#get-by-id-source)
        * [<strong>Query</strong>](#query-37)
        * [<strong>Result</strong>](#result-37)
     * [<strong>Read Collection Source</strong>](#read-collection-source)
        * [<strong>Query</strong>](#query-38)
        * [<strong>Result</strong>](#result-38)
     * [<strong>Read Source</strong>](#read-source)
        * [<strong>Query</strong>](#query-39)
        * [<strong>Result</strong>](#result-39)
     * [<strong>Update Source</strong>](#update-source)
        * [<strong>Query</strong>](#query-40)
        * [<strong>Result</strong>](#result-40)
  * [Tag](#tag)
     * [<strong>Create Tag</strong>](#create-tag)
        * [<strong>Query</strong>](#query-41)
        * [<strong>Result</strong>](#result-41)
     * [<strong>Destroy Tag</strong>](#destroy-tag)
        * [<strong>Query</strong>](#query-42)
        * [<strong>Result</strong>](#result-42)
     * [<strong>Read Tag</strong>](#read-tag)
        * [<strong>Query</strong>](#query-43)
        * [<strong>Result</strong>](#result-43)
  * [Task](#task)
     * [<strong>Create Task</strong>](#create-task)
        * [<strong>Query</strong>](#query-44)
        * [<strong>Result</strong>](#result-44)
     * [<strong>Destroy Task</strong>](#destroy-task)
        * [<strong>Query</strong>](#query-45)
        * [<strong>Result</strong>](#result-45)
  * [Team](#team)
     * [<strong>Create Team</strong>](#create-team)
        * [<strong>Query</strong>](#query-46)
        * [<strong>Result</strong>](#result-46)
     * [<strong>Destroy Team</strong>](#destroy-team)
        * [<strong>Query</strong>](#query-47)
        * [<strong>Result</strong>](#result-47)
     * [<strong>Get By Id Team</strong>](#get-by-id-team)
        * [<strong>Query</strong>](#query-48)
        * [<strong>Result</strong>](#result-48)
     * [<strong>Read Collection Team</strong>](#read-collection-team)
        * [<strong>Query</strong>](#query-49)
        * [<strong>Result</strong>](#result-49)
     * [<strong>Read Team</strong>](#read-team)
        * [<strong>Query</strong>](#query-50)
        * [<strong>Result</strong>](#result-50)
     * [<strong>Update Team</strong>](#update-team)
        * [<strong>Query</strong>](#query-51)
        * [<strong>Result</strong>](#result-51)
  * [Team User](#team-user)
     * [<strong>Create Team User</strong>](#create-team-user)
        * [<strong>Query</strong>](#query-52)
        * [<strong>Result</strong>](#result-52)
     * [<strong>Read Object Team User</strong>](#read-object-team-user)
        * [<strong>Query</strong>](#query-53)
        * [<strong>Result</strong>](#result-53)
     * [<strong>Read Team User</strong>](#read-team-user)
        * [<strong>Query</strong>](#query-54)
        * [<strong>Result</strong>](#result-54)
     * [<strong>Update Team User</strong>](#update-team-user)
        * [<strong>Query</strong>](#query-55)
        * [<strong>Result</strong>](#result-55)
  * [User](#user)
     * [<strong>Get By Id User</strong>](#get-by-id-user)
        * [<strong>Query</strong>](#query-56)
        * [<strong>Result</strong>](#result-56)
     * [<strong>Read Collection User</strong>](#read-collection-user)
        * [<strong>Query</strong>](#query-57)
        * [<strong>Result</strong>](#result-57)
     * [<strong>Read Object User</strong>](#read-object-user)
        * [<strong>Query</strong>](#query-58)
        * [<strong>Result</strong>](#result-58)
     * [<strong>Read User</strong>](#read-user)
        * [<strong>Query</strong>](#query-59)
        * [<strong>Result</strong>](#result-59)
     * [<strong>Update User</strong>](#update-user)
        * [<strong>Query</strong>](#query-60)
        * [<strong>Result</strong>](#result-60)
  * [Version](#version)
     * [<strong>Read Version</strong>](#read-version)
        * [<strong>Query</strong>](#query-61)
        * [<strong>Result</strong>](#result-61)

## Account

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
              "url": "http://URUAMVCFUX.com"
            }
          },
          {
            "node": {
              "url": "http://MYXEIWNSFF.com"
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
query read { root { accounts { edges { node { embed } } } } }
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
              "embed": {
                "url": "http://ZWSHFOXGSK.com",
                "provider": "twitter",
                "author_picture": "http://provider/picture.png",
                "title": "Foo Bar",
                "description": "Just a test",
                "type": "profile",
                "author_name": "Foo Bar",
                "refreshes_count": 1
              }
            }
          },
          {
            "node": {
              "embed": {
                "url": "http://GMJLHEVWHO.com",
                "provider": "twitter",
                "author_picture": "http://provider/picture.png",
                "title": "Foo Bar",
                "description": "Just a test",
                "type": "profile",
                "author_name": "Foo Bar",
                "refreshes_count": 1
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
                      "url": "http://NWIVQWHULB.com"
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
query read { root { accounts { edges { node { user { name } } } } } }
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
                "name": "VQMKYZHLEF"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "RKLBMZOIWP"
              }
            }
          }
        ]
      }
    }
  }
}
```


## Account Source

### __Create Account Source__

#### __Query__

```graphql
mutation create { createAccountSource(input: {account_id: 77, source_id: 1137, clientMutationId: "1"}) { account_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createAccountSource": {
      "account_source": {
        "id": "QWNjb3VudFNvdXJjZS8xMTY=\n"
      }
    }
  }
}
```

### __Create Account Source__

#### __Query__

```graphql
mutation create { createAccountSource(input: {source_id: 1137, url: "http://OQLMVNSRLR.com", clientMutationId: "1"}) { account_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createAccountSource": {
      "account_source": {
        "id": "QWNjb3VudFNvdXJjZS8xMTc=\n"
      }
    }
  }
}
```

### __Read Account Source__

#### __Query__

```graphql
query read { root { account_sources { edges { node { source_id } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "account_sources": {
        "edges": [
          {
            "node": {
              "source_id": 2906
            }
          },
          {
            "node": {
              "source_id": 2904
            }
          },
          {
            "node": {
              "source_id": 2909
            }
          },
          {
            "node": {
              "source_id": 2907
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC8yMDcx
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC8yMDcx\n"
    }
  }
}
```

### __Read Annotation__

#### __Query__

```graphql
query read { root { annotations { edges { node { annotated_id } } } } }
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
              "annotated_id": "163"
            }
          },
          {
            "node": {
              "annotated_id": "164"
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
query read { root { annotations { edges { node { annotator { name }, project_media { dbid } } } } } }
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
                "name": "QRNYLZDFMS"
              },
              "project_media": {
                "dbid": 203
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "ZBJHOEGIZF"
              },
              "project_media": {
                "dbid": 203
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
mutation create { createComment(input: {text: "test", annotated_type: "ProjectMedia", annotated_id: "152", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC8yMDMy\n"
      }
    }
  }
}
```

### __Destroy Comment__

#### __Query__

```graphql
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC8yMDcy
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC8yMDcy\n"
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
              "text": "GFPAXCRHJBASLGIBDUAQBZTNJXTHVSAMPDQAHJQATIDODASRJC"
            }
          },
          {
            "node": {
              "text": "DCGKZSTMNQGFBTSLGQLZELYMDRVQFUBDIMANLXMCWSDSISSEVV"
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
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 67, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC8z\n"
      }
    }
  }
}
```

### __Destroy Contact__

#### __Query__

```graphql
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC80
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC80\n"
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
              "location": "VDYJBSGLWW"
            }
          },
          {
            "node": {
              "location": "YCXYONHTRI"
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
                "name": "LBOQMZZPNW"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "OFDQVSGRCZ"
              }
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
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC8xMA==
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


## Dynamic

### __Create Dynamic__

#### __Query__

```graphql
mutation create { createDynamic(input: {set_fields: "{\"location_name\":\"Salvador\",\"location_position\":\"3,-51\"}", annotated_type: "ProjectMedia", annotated_id: "154", annotation_type: "location", clientMutationId: "1"}) { dynamic { id } } }
```

#### __Result__

```json
{
  "data": {
    "createDynamic": {
      "dynamic": {
        "id": "RHluYW1pYy8yMDQy\n"
      }
    }
  }
}
```


## Media

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
                "url": "http://JWBJOFIJCA.com"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://LRYNCKXSOU.com"
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
        "id": "UHJvamVjdC85MA==\n"
      }
    }
  }
}
```

### __Destroy Project__

#### __Query__

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8xMTA=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8xMTA=\n"
    }
  }
}
```

### __Read Collection Project__

#### __Query__

```graphql
query read { root { projects { edges { node { sources { edges { node { name } } }, project_medias { edges { node { media_id } } }, project_sources { edges { node { source_id } } } } } } } }
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
                      "name": "LECJTMIFFT"
                    }
                  },
                  {
                    "node": {
                      "name": "Foo Bar"
                    }
                  },
                  {
                    "node": {
                      "name": "BUYSCFGCCC"
                    }
                  }
                ]
              },
              "project_medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 202
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "source_id": 2949
                    }
                  },
                  {
                    "node": {
                      "source_id": 2955
                    }
                  },
                  {
                    "node": {
                      "source_id": 2958
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
              "project_medias": {
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
              "sources": {
                "edges": [

                ]
              },
              "project_medias": {
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
                "name": "BSVVCTPOUS"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "VWNLMJMPXF"
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
              "title": "ZOVVXHNLRJ"
            }
          },
          {
            "node": {
              "title": "PMVVJXETLD"
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
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8yNzI=
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


## Project Media

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {project_id: 86, url: "http://DEGPNURGDQ.com", clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzE1NQ==\n"
      }
    }
  }
}
```

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {project_id: 86, quote: "media quote", quote_attributions: "{\"name\":\"source name\"}", clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzE1Ng==\n"
      }
    }
  }
}
```

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {media_id: 158, project_id: 92, clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzE1OA==\n"
      }
    }
  }
}
```

### __Read Object Project Media__

#### __Query__

```graphql
query read { root { project_medias { edges { node { project { title }, media { url } } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "project_medias": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "CMNJJESXLR"
              },
              "media": {
                "url": "http://VWLSXHJHJO.com"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "CPMXPFVMER"
              },
              "media": {
                "url": "http://BTLCIVBOHM.com"
              }
            }
          }
        ]
      }
    }
  }
}
```

### __Read Project Media__

#### __Query__

```graphql
query read { root { project_medias { edges { node { last_status } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "project_medias": {
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


## Project Source

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {source_id: 1187, project_id: 96, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS84NQ==\n"
      }
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {name: "New source", project_id: 96, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS84Ng==\n"
      }
    }
  }
}
```

### __Destroy Project Source__

#### __Query__

```graphql
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS85MQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS85MQ==\n"
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
                "title": "IXDLAUGMWD"
              },
              "source": {
                "name": "UGLQXTNJDV"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "EZXXQFIAHL"
              },
              "source": {
                "name": "JCFTZCCKLC"
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
              "source_id": 3146
            }
          },
          {
            "node": {
              "source_id": 3149
            }
          }
        ]
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
        "id": "U291cmNlLzExOTQ=\n"
      }
    }
  }
}
```

### __Get By Id Source__

#### __Query__

```graphql
query GetById { source(id: "2840") { name } }
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

### __Read Collection Source__

#### __Query__

```graphql
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } }, medias { edges { node { media_id } } }, collaborators { edges { node { name } } } } } } } }
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
                      "title": "DUVYPEPXIG"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [

                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 193
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
                      "title": "JWFVWZMCXL"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://BOEGINXGVV.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 192
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 203
                    }
                  }
                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
                      "url": "http://EXIATGFIGP.com"
                    }
                  }
                ]
              },
              "project_sources": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
                      "url": "http://BVNKCFXMND.com"
                    }
                  }
                ]
              },
              "project_sources": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
              "medias": {
                "edges": [

                ]
              },
              "collaborators": {
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
                      "title": "HMHNBQCZCH"
                    }
                  },
                  {
                    "node": {
                      "title": "ZDKVQWFDAA"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://BVNKCFXMND.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://BOEGINXGVV.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 190
                    }
                  },
                  {
                    "node": {
                      "project_id": 191
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 203
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "PPUZDPIJHK"
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
              "image": "http://localhost:3000/images/user.png"
            }
          },
          {
            "node": {
              "image": "http://localhost:3000/images/source.png"
            }
          },
          {
            "node": {
              "image": "http://localhost:3000/images/user.png"
            }
          },
          {
            "node": {
              "image": "http://localhost:3000/images/source.png"
            }
          },
          {
            "node": {
              "image": "http://localhost:3000/images/user.png"
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
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzM0MDk=
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


## Tag

### __Create Tag__

#### __Query__

```graphql
mutation create { createTag(input: {tag: "egypt", annotated_type: "ProjectMedia", annotated_id: "160", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnLzIwNjU=\n"
      }
    }
  }
}
```

### __Destroy Tag__

#### __Query__

```graphql
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnLzIwNzM=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnLzIwNzM=\n"
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
              "tag": "11"
            }
          },
          {
            "node": {
              "tag": "12"
            }
          }
        ]
      }
    }
  }
}
```


## Task

### __Create Task__

#### __Query__

```graphql
mutation create { createTask(input: {label: "test", type: "yes_no", annotated_type: "ProjectMedia", annotated_id: "161", clientMutationId: "1"}) { task { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTask": {
      "task": {
        "id": "VGFzay8yMDcw\n"
      }
    }
  }
}
```

### __Destroy Task__

#### __Query__

```graphql
mutation destroy { destroyTask(input: { clientMutationId: "1", id: "VGFzay8yMDc4
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTask": {
      "deletedId": "VGFzay8yMDc4\n"
    }
  }
}
```


## Team

### __Create Team__

#### __Query__

```graphql
mutation create { createTeam(input: {name: "test", description: "test", slug: "test", clientMutationId: "1"}) { team { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeam": {
      "team": {
        "id": "VGVhbS84MA==\n"
      }
    }
  }
}
```

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS84OQ==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS84OQ==\n"
    }
  }
}
```

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "126") { name } }
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
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, join_requests { edges { node { user_id } } }, users { edges { node { name } } }, contacts { edges { node { location } } }, projects { edges { node { title } } }, sources { edges { node { name } } } } } } } }
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

                ]
              },
              "join_requests": {
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
              },
              "sources": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "team_users": {
                "edges": [
                  {
                    "node": {
                      "user_id": 2687
                    }
                  },
                  {
                    "node": {
                      "user_id": 2689
                    }
                  }
                ]
              },
              "join_requests": {
                "edges": [
                  {
                    "node": {
                      "user_id": 2688
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "JLAFGSTEFX"
                    }
                  },
                  {
                    "node": {
                      "name": "IBUZEWUXVL"
                    }
                  },
                  {
                    "node": {
                      "name": "HGUHKNRDUG"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "SDALPUQKLM"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "DPSXWKRMMX"
                    }
                  }
                ]
              },
              "sources": {
                "edges": [
                  {
                    "node": {
                      "name": "JAAPHHCNLT"
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
              "join_requests": {
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
              },
              "sources": {
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
              "join_requests": {
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
              },
              "sources": {
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
              "name": "RXLHVVDGDI"
            }
          },
          {
            "node": {
              "name": "LJOGRQTJVO"
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
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8yNDM=
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

### __Create Team User__

#### __Query__

```graphql
mutation create { createTeamUser(input: {team_id: 81, user_id: 1078, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvODI=\n"
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
                "name": "XUTFBUTSNP"
              },
              "user": {
                "name": "FYWZJTFLZK"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "PEIEWZIVPC"
              },
              "user": {
                "name": "ERNPGVMYZK"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "CWYQJQKXVZ"
              },
              "user": {
                "name": "XEDQTGCUHP"
              }
            }
          }
        ]
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
              "user_id": 2851
            }
          },
          {
            "node": {
              "user_id": 2852
            }
          },
          {
            "node": {
              "user_id": 2850
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
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMjA1
", team_id: 244 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 244
      }
    }
  }
}
```


## User

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "2591") { name } }
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
query read { root { users { edges { node { teams { edges { node { name } } }, team_users { edges { node { role } } }, annotations { edges { node { content } } } } } } } }
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

                ]
              },
              "team_users": {
                "edges": [

                ]
              },
              "annotations": {
                "edges": [

                ]
              }
            }
          },
          {
            "node": {
              "teams": {
                "edges": [
                  {
                    "node": {
                      "name": "RFVLOSNEDJ"
                    }
                  },
                  {
                    "node": {
                      "name": "NFKXZKFKRK"
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
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"AYMHVFLVYGNSQQHJIGXCGFPTOSLGJUZNNZUHTJDGZATMRTRMMV\"}"
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
              },
              "annotations": {
                "edges": [
                  {
                    "node": {
                      "content": "{\"text\":\"FPSINZZWHJKRIXCTBDXOBCDODLWRGQSGCBIEKJGJVLPGHBRXAL\"}"
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
              },
              "annotations": {
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
                "name": "LXJDMBIMJG"
              },
              "current_team": {
                "name": "IYXVBXVMXS"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "UWLXEAWYTH"
              },
              "current_team": {
                "name": "IYXVBXVMXS"
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
              "email": "zqyteqraov@utkxlfmsdo.com"
            }
          },
          {
            "node": {
              "email": "dauoqhpaoq@xetoynyivf.com"
            }
          },
          {
            "node": {
              "email": "jtfournkux@lpvhdflzfb.com"
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
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8zMDUz
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


## Version

### __Read Version__

#### __Query__

```graphql
query read { root { versions { edges { node { dbid } } } } }
```

#### __Result__

```json
{
  "data": {
    "root": {
      "versions": {
        "edges": [
          {
            "node": {
              "dbid": 1846
            }
          },
          {
            "node": {
              "dbid": 1847
            }
          }
        ]
      }
    }
  }
}
```

