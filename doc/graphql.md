# GraphQL Documentation

You can test the GraphQL endpoint by going to *"/graphiql"*. The available actions are:

  * [Account](#account)
     * [<strong>Read Object Account</strong>](#read-object-account)
        * [<strong>Query</strong>](#query)
        * [<strong>Result</strong>](#result)
     * [<strong>Create Account</strong>](#create-account)
        * [<strong>Query</strong>](#query-1)
        * [<strong>Result</strong>](#result-1)
     * [<strong>Read Account</strong>](#read-account)
        * [<strong>Query</strong>](#query-2)
        * [<strong>Result</strong>](#result-2)
     * [<strong>Read Account</strong>](#read-account-1)
        * [<strong>Query</strong>](#query-3)
        * [<strong>Result</strong>](#result-3)
     * [<strong>Read Collection Account</strong>](#read-collection-account)
        * [<strong>Query</strong>](#query-4)
        * [<strong>Result</strong>](#result-4)
  * [Account Source](#account-source)
     * [<strong>Read Account Source</strong>](#read-account-source)
        * [<strong>Query</strong>](#query-5)
        * [<strong>Result</strong>](#result-5)
     * [<strong>Create Account Source</strong>](#create-account-source)
        * [<strong>Query</strong>](#query-6)
        * [<strong>Result</strong>](#result-6)
     * [<strong>Create Account Source</strong>](#create-account-source-1)
        * [<strong>Query</strong>](#query-7)
        * [<strong>Result</strong>](#result-7)
  * [Annotation](#annotation)
     * [<strong>Read Annotation</strong>](#read-annotation)
        * [<strong>Query</strong>](#query-8)
        * [<strong>Result</strong>](#result-8)
     * [<strong>Destroy Annotation</strong>](#destroy-annotation)
        * [<strong>Query</strong>](#query-9)
        * [<strong>Result</strong>](#result-9)
     * [<strong>Read Object Annotation</strong>](#read-object-annotation)
        * [<strong>Query</strong>](#query-10)
        * [<strong>Result</strong>](#result-10)
  * [Comment](#comment)
     * [<strong>Read Comment</strong>](#read-comment)
        * [<strong>Query</strong>](#query-11)
        * [<strong>Result</strong>](#result-11)
     * [<strong>Destroy Comment</strong>](#destroy-comment)
        * [<strong>Query</strong>](#query-12)
        * [<strong>Result</strong>](#result-12)
     * [<strong>Create Comment</strong>](#create-comment)
        * [<strong>Query</strong>](#query-13)
        * [<strong>Result</strong>](#result-13)
  * [Contact](#contact)
     * [<strong>Update Contact</strong>](#update-contact)
        * [<strong>Query</strong>](#query-14)
        * [<strong>Result</strong>](#result-14)
     * [<strong>Destroy Contact</strong>](#destroy-contact)
        * [<strong>Query</strong>](#query-15)
        * [<strong>Result</strong>](#result-15)
     * [<strong>Read Contact</strong>](#read-contact)
        * [<strong>Query</strong>](#query-16)
        * [<strong>Result</strong>](#result-16)
     * [<strong>Read Object Contact</strong>](#read-object-contact)
        * [<strong>Query</strong>](#query-17)
        * [<strong>Result</strong>](#result-17)
     * [<strong>Create Contact</strong>](#create-contact)
        * [<strong>Query</strong>](#query-18)
        * [<strong>Result</strong>](#result-18)
  * [Dynamic](#dynamic)
     * [<strong>Create Dynamic</strong>](#create-dynamic)
        * [<strong>Query</strong>](#query-19)
        * [<strong>Result</strong>](#result-19)
  * [Media](#media)
     * [<strong>Read Object Media</strong>](#read-object-media)
        * [<strong>Query</strong>](#query-20)
        * [<strong>Result</strong>](#result-20)
  * [Project](#project)
     * [<strong>Read Collection Project</strong>](#read-collection-project)
        * [<strong>Query</strong>](#query-21)
        * [<strong>Result</strong>](#result-21)
     * [<strong>Update Project</strong>](#update-project)
        * [<strong>Query</strong>](#query-22)
        * [<strong>Result</strong>](#result-22)
     * [<strong>Read Object Project</strong>](#read-object-project)
        * [<strong>Query</strong>](#query-23)
        * [<strong>Result</strong>](#result-23)
     * [<strong>Create Project</strong>](#create-project)
        * [<strong>Query</strong>](#query-24)
        * [<strong>Result</strong>](#result-24)
     * [<strong>Destroy Project</strong>](#destroy-project)
        * [<strong>Query</strong>](#query-25)
        * [<strong>Result</strong>](#result-25)
     * [<strong>Read Project</strong>](#read-project)
        * [<strong>Query</strong>](#query-26)
        * [<strong>Result</strong>](#result-26)
  * [Project Media](#project-media)
     * [<strong>Read Project Media</strong>](#read-project-media)
        * [<strong>Query</strong>](#query-27)
        * [<strong>Result</strong>](#result-27)
     * [<strong>Create Project Media</strong>](#create-project-media)
        * [<strong>Query</strong>](#query-28)
        * [<strong>Result</strong>](#result-28)
     * [<strong>Create Project Media</strong>](#create-project-media-1)
        * [<strong>Query</strong>](#query-29)
        * [<strong>Result</strong>](#result-29)
     * [<strong>Create Project Media</strong>](#create-project-media-2)
        * [<strong>Query</strong>](#query-30)
        * [<strong>Result</strong>](#result-30)
     * [<strong>Read Object Project Media</strong>](#read-object-project-media)
        * [<strong>Query</strong>](#query-31)
        * [<strong>Result</strong>](#result-31)
  * [Project Source](#project-source)
     * [<strong>Destroy Project Source</strong>](#destroy-project-source)
        * [<strong>Query</strong>](#query-32)
        * [<strong>Result</strong>](#result-32)
     * [<strong>Read Project Source</strong>](#read-project-source)
        * [<strong>Query</strong>](#query-33)
        * [<strong>Result</strong>](#result-33)
     * [<strong>Read Object Project Source</strong>](#read-object-project-source)
        * [<strong>Query</strong>](#query-34)
        * [<strong>Result</strong>](#result-34)
     * [<strong>Create Project Source</strong>](#create-project-source)
        * [<strong>Query</strong>](#query-35)
        * [<strong>Result</strong>](#result-35)
     * [<strong>Create Project Source</strong>](#create-project-source-1)
        * [<strong>Query</strong>](#query-36)
        * [<strong>Result</strong>](#result-36)
  * [Source](#source)
     * [<strong>Read Collection Source</strong>](#read-collection-source)
        * [<strong>Query</strong>](#query-37)
        * [<strong>Result</strong>](#result-37)
     * [<strong>Update Source</strong>](#update-source)
        * [<strong>Query</strong>](#query-38)
        * [<strong>Result</strong>](#result-38)
     * [<strong>Get By Id Source</strong>](#get-by-id-source)
        * [<strong>Query</strong>](#query-39)
        * [<strong>Result</strong>](#result-39)
     * [<strong>Create Source</strong>](#create-source)
        * [<strong>Query</strong>](#query-40)
        * [<strong>Result</strong>](#result-40)
     * [<strong>Read Source</strong>](#read-source)
        * [<strong>Query</strong>](#query-41)
        * [<strong>Result</strong>](#result-41)
  * [Tag](#tag)
     * [<strong>Destroy Tag</strong>](#destroy-tag)
        * [<strong>Query</strong>](#query-42)
        * [<strong>Result</strong>](#result-42)
     * [<strong>Read Tag</strong>](#read-tag)
        * [<strong>Query</strong>](#query-43)
        * [<strong>Result</strong>](#result-43)
     * [<strong>Create Tag</strong>](#create-tag)
        * [<strong>Query</strong>](#query-44)
        * [<strong>Result</strong>](#result-44)
  * [Task](#task)
     * [<strong>Create Task</strong>](#create-task)
        * [<strong>Query</strong>](#query-45)
        * [<strong>Result</strong>](#result-45)
     * [<strong>Destroy Task</strong>](#destroy-task)
        * [<strong>Query</strong>](#query-46)
        * [<strong>Result</strong>](#result-46)
  * [Team](#team)
     * [<strong>Read Collection Team</strong>](#read-collection-team)
        * [<strong>Query</strong>](#query-47)
        * [<strong>Result</strong>](#result-47)
     * [<strong>Get By Id Team</strong>](#get-by-id-team)
        * [<strong>Query</strong>](#query-48)
        * [<strong>Result</strong>](#result-48)
     * [<strong>Create Team</strong>](#create-team)
        * [<strong>Query</strong>](#query-49)
        * [<strong>Result</strong>](#result-49)
     * [<strong>Destroy Team</strong>](#destroy-team)
        * [<strong>Query</strong>](#query-50)
        * [<strong>Result</strong>](#result-50)
     * [<strong>Update Team</strong>](#update-team)
        * [<strong>Query</strong>](#query-51)
        * [<strong>Result</strong>](#result-51)
     * [<strong>Read Team</strong>](#read-team)
        * [<strong>Query</strong>](#query-52)
        * [<strong>Result</strong>](#result-52)
  * [Team User](#team-user)
     * [<strong>Update Team User</strong>](#update-team-user)
        * [<strong>Query</strong>](#query-53)
        * [<strong>Result</strong>](#result-53)
     * [<strong>Read Object Team User</strong>](#read-object-team-user)
        * [<strong>Query</strong>](#query-54)
        * [<strong>Result</strong>](#result-54)
     * [<strong>Create Team User</strong>](#create-team-user)
        * [<strong>Query</strong>](#query-55)
        * [<strong>Result</strong>](#result-55)
     * [<strong>Read Team User</strong>](#read-team-user)
        * [<strong>Query</strong>](#query-56)
        * [<strong>Result</strong>](#result-56)
  * [User](#user)
     * [<strong>Update User</strong>](#update-user)
        * [<strong>Query</strong>](#query-57)
        * [<strong>Result</strong>](#result-57)
     * [<strong>Read Object User</strong>](#read-object-user)
        * [<strong>Query</strong>](#query-58)
        * [<strong>Result</strong>](#result-58)
     * [<strong>Read User</strong>](#read-user)
        * [<strong>Query</strong>](#query-59)
        * [<strong>Result</strong>](#result-59)
     * [<strong>Read Collection User</strong>](#read-collection-user)
        * [<strong>Query</strong>](#query-60)
        * [<strong>Result</strong>](#result-60)
     * [<strong>Get By Id User</strong>](#get-by-id-user)
        * [<strong>Query</strong>](#query-61)
        * [<strong>Result</strong>](#result-61)
  * [Version](#version)
     * [<strong>Read Version</strong>](#read-version)
        * [<strong>Query</strong>](#query-62)
        * [<strong>Result</strong>](#result-62)

## Account

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
                "name": "JVVZNLHBYZ"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "JNVXBWVEHA"
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
        "id": "QWNjb3VudC81MDE=\n"
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
              "url": "http://WLKGWETIAC.com"
            }
          },
          {
            "node": {
              "url": "http://DWUVCOVNBW.com"
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
                "url": "http://MEAIAIFAFA.com",
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
                "url": "http://JFKYDULLWC.com",
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
                      "url": "http://DQJZORNUPM.com"
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


## Account Source

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
              "source_id": 9856
            }
          },
          {
            "node": {
              "source_id": 9854
            }
          },
          {
            "node": {
              "source_id": 9859
            }
          },
          {
            "node": {
              "source_id": 9857
            }
          }
        ]
      }
    }
  }
}
```

### __Create Account Source__

#### __Query__

```graphql
mutation create { createAccountSource(input: {account_id: 558, source_id: 9868, clientMutationId: "1"}) { account_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createAccountSource": {
      "account_source": {
        "id": "QWNjb3VudFNvdXJjZS85MzE=\n"
      }
    }
  }
}
```

### __Create Account Source__

#### __Query__

```graphql
mutation create { createAccountSource(input: {source_id: 9868, url: "http://JBTGYHNAIT.com", clientMutationId: "1"}) { account_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createAccountSource": {
      "account_source": {
        "id": "QWNjb3VudFNvdXJjZS85MzI=\n"
      }
    }
  }
}
```


## Annotation

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
              "annotated_id": "561"
            }
          },
          {
            "node": {
              "annotated_id": "562"
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC81Njg0
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC81Njg0\n"
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
                "name": "IRCHAMQJGW"
              },
              "project_media": {
                "dbid": 454
              }
            }
          },
          {
            "node": {
              "annotator": {
                "name": "ENZIXPSJPW"
              },
              "project_media": {
                "dbid": 454
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
              "text": "EJTHYPICCJVKGRTLJMDJGRMFFGHAVDHUAZFYPYZWQMSSLDLKHM"
            }
          },
          {
            "node": {
              "text": "YBKTVNBOZONSKFYMPXWFAXOQUYCJGKXITRCRYKJOIDNRHIHINO"
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
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC81NDA4
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC81NDA4\n"
    }
  }
}
```

### __Create Comment__

#### __Query__

```graphql
mutation create { createComment(input: {text: "test", annotated_type: "ProjectMedia", annotated_id: "440", clientMutationId: "1"}) { comment { id } } }
```

#### __Result__

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC81NjM4\n"
      }
    }
  }
}
```


## Contact

### __Update Contact__

#### __Query__

```graphql
mutation update { updateContact(input: { clientMutationId: "1", id: "Q29udGFjdC8yNQ==
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
mutation destroy { destroyContact(input: { clientMutationId: "1", id: "Q29udGFjdC8yNg==
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyContact": {
      "deletedId": "Q29udGFjdC8yNg==\n"
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
              "location": "SCLNVNIEGC"
            }
          },
          {
            "node": {
              "location": "OFJIGQILTC"
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
                "name": "DLJPDQVCNP"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "CYRHIIXOPD"
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
mutation create { createContact(input: {location: "my location", phone: "00201099998888", team_id: 804, clientMutationId: "1"}) { contact { id } } }
```

#### __Result__

```json
{
  "data": {
    "createContact": {
      "contact": {
        "id": "Q29udGFjdC8zMg==\n"
      }
    }
  }
}
```


## Dynamic

### __Create Dynamic__

#### __Query__

```graphql
mutation create { createDynamic(input: {set_fields: "{\"location_name\":\"Salvador\",\"location_position\":\"3,-51\"}", annotated_type: "ProjectMedia", annotated_id: "455", annotation_type: "location", clientMutationId: "1"}) { dynamic { id } } }
```

#### __Result__

```json
{
  "data": {
    "createDynamic": {
      "dynamic": {
        "id": "RHluYW1pYy81NzA0\n"
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
                "url": "http://CWDPXKLBQS.com"
              }
            }
          },
          {
            "node": {
              "account": {
                "url": "http://HJANNHDFEG.com"
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
                      "name": "GYJBQMHNSC"
                    }
                  },
                  {
                    "node": {
                      "name": "Foo Bar"
                    }
                  },
                  {
                    "node": {
                      "name": "OZJTRDAFPT"
                    }
                  }
                ]
              },
              "project_medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 376
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "source_id": 8234
                    }
                  },
                  {
                    "node": {
                      "source_id": 8240
                    }
                  },
                  {
                    "node": {
                      "source_id": 8243
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

### __Update Project__

#### __Query__

```graphql
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC84MDA=
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
                "name": "WGUGMXRKDD"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "ZNDVMDAKNX"
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
        "id": "UHJvamVjdC84Mzk=\n"
      }
    }
  }
}
```

### __Destroy Project__

#### __Query__

```graphql
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC84NDE=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC84NDE=\n"
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
              "title": "JDJLPXGLJB"
            }
          },
          {
            "node": {
              "title": "PTYTKBOJUN"
            }
          }
        ]
      }
    }
  }
}
```


## Project Media

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

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {media_id: 380, project_id: 711, clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzM3NQ==\n"
      }
    }
  }
}
```

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {project_id: 746, url: "http://BAZYBGZXXT.com", clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzQwNg==\n"
      }
    }
  }
}
```

### __Create Project Media__

#### __Query__

```graphql
mutation create { createProjectMedia(input: {project_id: 746, quote: "media quote", quote_attributions: "{\"name\":\"source name\"}", clientMutationId: "1"}) { project_media { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "id": "UHJvamVjdE1lZGlhLzQwNw==\n"
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
                "title": "GPUGHAUBGV"
              },
              "media": {
                "url": "http://TINHKVNEYB.com"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "IXVURJCIWO"
              },
              "media": {
                "url": "http://ZJPPHPYUPG.com"
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
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS81MjI=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS81MjI=\n"
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
              "source_id": 8219
            }
          },
          {
            "node": {
              "source_id": 8222
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
                "title": "HHRMGVGKKM"
              },
              "source": {
                "name": "YTPPFBKAFM"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "NTZZPLSGGZ"
              },
              "source": {
                "name": "NBFHNNQBER"
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
mutation create { createProjectSource(input: {source_id: 10388, project_id: 862, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS82ODA=\n"
      }
    }
  }
}
```

### __Create Project Source__

#### __Query__

```graphql
mutation create { createProjectSource(input: {name: "New source", project_id: 862, clientMutationId: "1"}) { project_source { id } } }
```

#### __Result__

```json
{
  "data": {
    "createProjectSource": {
      "project_source": {
        "id": "UHJvamVjdFNvdXJjZS82ODE=\n"
      }
    }
  }
}
```


## Source

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
                      "title": "RYHUXBWVHL"
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
                      "project_id": 691
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
                      "title": "HBNGDPFBQK"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://GZQVEBWJBX.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 690
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 375
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
                      "url": "http://AXXJXEZYZT.com"
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
                      "url": "http://MGPRSGKNBB.com"
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
                      "title": "MXIXHBLNPZ"
                    }
                  },
                  {
                    "node": {
                      "title": "YHUSDKTFMK"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "http://MGPRSGKNBB.com"
                    }
                  },
                  {
                    "node": {
                      "url": "http://GZQVEBWJBX.com"
                    }
                  }
                ]
              },
              "project_sources": {
                "edges": [
                  {
                    "node": {
                      "project_id": 688
                    }
                  },
                  {
                    "node": {
                      "project_id": 689
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "media_id": 375
                    }
                  }
                ]
              },
              "collaborators": {
                "edges": [
                  {
                    "node": {
                      "name": "LLAKHHZOVN"
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
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzk5MDQ=
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
query GetById { source(id: "10171") { name } }
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
        "id": "U291cmNlLzEwNDMw\n"
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
              "image": "http://api.test:13000/images/user.png"
            }
          },
          {
            "node": {
              "image": "http://api.test:13000/images/source.png"
            }
          },
          {
            "node": {
              "image": "http://api.test:13000/images/user.png"
            }
          },
          {
            "node": {
              "image": "http://api.test:13000/images/source.png"
            }
          },
          {
            "node": {
              "image": "http://api.test:13000/images/user.png"
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
mutation destroy { destroyTag(input: { clientMutationId: "1", id: "VGFnLzQ1OTc=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTag": {
      "deletedId": "VGFnLzQ1OTc=\n"
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
              "tag": "GVIITEQBSYBFSBZDHVILNDUCXCNNLYNDCZULPAJIZUMVWGNVDD"
            }
          },
          {
            "node": {
              "tag": "RXHKIXTEKOMPTHUHAWMGPALHQIZNRYQXSJPBFOQNUEBXRNDXCU"
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
mutation create { createTag(input: {tag: "egypt", annotated_type: "ProjectMedia", annotated_id: "453", clientMutationId: "1"}) { tag { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTag": {
      "tag": {
        "id": "VGFnLzU2OTM=\n"
      }
    }
  }
}
```


## Task

### __Create Task__

#### __Query__

```graphql
mutation create { createTask(input: {label: "test", type: "yes_no", annotated_type: "ProjectMedia", annotated_id: "428", clientMutationId: "1"}) { task { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTask": {
      "task": {
        "id": "VGFzay81NTgz\n"
      }
    }
  }
}
```

### __Destroy Task__

#### __Query__

```graphql
mutation destroy { destroyTask(input: { clientMutationId: "1", id: "VGFzay81NTky
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTask": {
      "deletedId": "VGFzay81NTky\n"
    }
  }
}
```


## Team

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
                      "user_id": 8803
                    }
                  },
                  {
                    "node": {
                      "user_id": 8804
                    }
                  },
                  {
                    "node": {
                      "user_id": 8805
                    }
                  }
                ]
              },
              "join_requests": {
                "edges": [
                  {
                    "node": {
                      "user_id": 8804
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "CVWKQGUCCG"
                    }
                  },
                  {
                    "node": {
                      "name": "NGUMWZSBBE"
                    }
                  },
                  {
                    "node": {
                      "name": "SJWLNMLSSK"
                    }
                  }
                ]
              },
              "contacts": {
                "edges": [
                  {
                    "node": {
                      "location": "MIQALWAVEW"
                    }
                  }
                ]
              },
              "projects": {
                "edges": [
                  {
                    "node": {
                      "title": "NXXTDVLOTR"
                    }
                  }
                ]
              },
              "sources": {
                "edges": [
                  {
                    "node": {
                      "name": "WXVYGYWFRM"
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

### __Get By Id Team__

#### __Query__

```graphql
query GetById { team(id: "725") { name } }
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
mutation create { createTeam(input: {name: "test", description: "test", slug: "test", clientMutationId: "1"}) { team { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeam": {
      "team": {
        "id": "VGVhbS83Mzc=\n"
      }
    }
  }
}
```

### __Destroy Team__

#### __Query__

```graphql
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS83NTM=
" }) { deletedId } }
```

#### __Result__

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS83NTM=\n"
    }
  }
}
```

### __Update Team__

#### __Query__

```graphql
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS83NTc=
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
              "name": "PHDPQJXDTD"
            }
          },
          {
            "node": {
              "name": "VQRAWYAUVS"
            }
          }
        ]
      }
    }
  }
}
```


## Team User

### __Update Team User__

#### __Query__

```graphql
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvNTEy
", team_id: 677 }) { team_user { team_id } } }
```

#### __Result__

```json
{
  "data": {
    "updateTeamUser": {
      "team_user": {
        "team_id": 677
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
                "name": "QJQZRWREKE"
              },
              "user": {
                "name": "TLQNHRWXYV"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "ZZHEHMJXIB"
              },
              "user": {
                "name": "QLCKXQHKMG"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "RJYOSKAQZG"
              },
              "user": {
                "name": "VYAXJSJIFF"
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
mutation create { createTeamUser(input: {team_id: 769, user_id: 9185, status: "member", clientMutationId: "1"}) { team_user { id } } }
```

#### __Result__

```json
{
  "data": {
    "createTeamUser": {
      "team_user": {
        "id": "VGVhbVVzZXIvNTgz\n"
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
              "user_id": 9189
            }
          },
          {
            "node": {
              "user_id": 9190
            }
          },
          {
            "node": {
              "user_id": 9188
            }
          }
        ]
      }
    }
  }
}
```


## User

### __Update User__

#### __Query__

```graphql
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci83MDU3
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
                "name": "NYDUQWFKMW"
              },
              "current_team": {
                "name": "FAWZVZLFHW"
              }
            }
          },
          {
            "node": {
              "source": {
                "name": "XCESPRXYHG"
              },
              "current_team": {
                "name": "FAWZVZLFHW"
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
              "email": "mrotlwkkps@xdkzpwfils.com"
            }
          },
          {
            "node": {
              "email": "mnejhpykap@mkyylgarbv.com"
            }
          },
          {
            "node": {
              "email": "ygttcuinsm@yywejrfvzg.com"
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
                      "name": "OQTWNDIAML"
                    }
                  },
                  {
                    "node": {
                      "name": "QUSXUTZVVG"
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
                      "content": "{\"text\":\"HAHTFYZLVDRIWGNAXTDYXXNBWNGICREITRDQUABPMEIBIRRDON\"}"
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
                      "content": "{\"text\":\"AHMSDVSCVKDEFWQQJPJSKTJRBNXHMOEAEBWSQKQYIRMWPFAOKG\"}"
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

### __Get By Id User__

#### __Query__

```graphql
query GetById { user(id: "8849") { name } }
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
              "dbid": 4669
            }
          },
          {
            "node": {
              "dbid": 4670
            }
          }
        ]
      }
    }
  }
}
```

