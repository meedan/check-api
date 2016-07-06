### GraphQL

You can test the GraphQL endpoint by going to `/graphiql`. The available actions are:

#### Destroy Team

** Query **

```json
mutation destroy { destroyTeam(input: { clientMutationId: "1", id: "VGVhbS8x
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyTeam": {
      "deletedId": "VGVhbS8x\n"
    }
  }
}
```

#### Read Object Project Source

** Query **

```json
query read { root { project_sources { edges { node { project { title }, source { name } } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "project_sources": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "UGTHTNXRYC"
              },
              "source": {
                "name": "SQQWEJKORR"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "LJIVFYXTUF"
              },
              "source": {
                "name": "RWDPFAXPYX"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Create Api Key

** Query **

```json
mutation create { createApiKey(input: {application: "test", clientMutationId: "1"}) { api_key { id } } }
```

** Result **

```json
{
  "data": {
    "createApiKey": {
      "api_key": {
        "id": "QXBpS2V5LzI=\n"
      }
    }
  }
}
```

#### Update User

** Query **

```json
mutation update { updateUser(input: { clientMutationId: "1", id: "VXNlci8z
", name: "Bar" }) { user { name } } }
```

** Result **

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

#### Create Media

** Query **

```json
mutation create { createMedia(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { media { id } } }
```

** Result **

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

#### Destroy Account

** Query **

```json
mutation destroy { destroyAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyAccount": {
      "deletedId": "QWNjb3VudC8x\n"
    }
  }
}
```

#### Destroy Comment

** Query **

```json
mutation destroy { destroyComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlc5cEMteXQ3a2dpSVY3Y19xeA==
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyComment": {
      "deletedId": "Q29tbWVudC9BVlc5cEMteXQ3a2dpSVY3Y19xeA==\n"
    }
  }
}
```

#### Read Project Source

** Query **

```json
query read { root { project_sources { edges { node { source_id } } } } }
```

** Result **

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

#### Read User

** Query **

```json
query read { root { users { edges { node { email } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "users": {
        "edges": [
          {
            "node": {
              "email": "ydfvtzkvsy@zszaxpjeql.com"
            }
          },
          {
            "node": {
              "email": "tuyqluwenb@nxhrtaduzp.com"
            }
          }
        ]
      }
    }
  }
}
```

#### Read Object Media

** Query **

```json
query read { root { medias { edges { node { project { title }, account { url }, user { name } } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "project": {
                "title": "MOROFCHBKX"
              },
              "account": {
                "url": "https://www.youtube.com/user/MeedanTube"
              },
              "user": {
                "name": "IHNTQBWRED"
              }
            }
          },
          {
            "node": {
              "project": {
                "title": "CJXANKKGYW"
              },
              "account": {
                "url": "https://www.youtube.com/user/MeedanTube"
              },
              "user": {
                "name": "GJOWDYMGAI"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update Comment

** Query **

```json
mutation update { updateComment(input: { clientMutationId: "1", id: "Q29tbWVudC9BVlc5cERuRXQ3a2dpSVY3Y19xeQ==
", text: "bar" }) { comment { text } } }
```

** Result **

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

#### Destroy Project Source

** Query **

```json
mutation destroy { destroyProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyProjectSource": {
      "deletedId": "UHJvamVjdFNvdXJjZS8x\n"
    }
  }
}
```

#### Read Object Account

** Query **

```json
query read { root { accounts { edges { node { user { name }, source { name } } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "SNOEAXZAGS"
              },
              "source": {
                "name": "MAPRQRAXZK"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "NOLYLBNGEE"
              },
              "source": {
                "name": "PSEWUTJGGN"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Create Account

** Query **

```json
mutation create { createAccount(input: {url: "https://www.youtube.com/user/MeedanTube", clientMutationId: "1"}) { account { id } } }
```

** Result **

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

#### Destroy Project

** Query **

```json
mutation destroy { destroyProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyProject": {
      "deletedId": "UHJvamVjdC8x\n"
    }
  }
}
```

#### Destroy User

** Query **

```json
mutation destroy { destroyUser(input: { clientMutationId: "1", id: "VXNlci8z
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyUser": {
      "deletedId": "VXNlci8z\n"
    }
  }
}
```

#### Update Source

** Query **

```json
mutation update { updateSource(input: { clientMutationId: "1", id: "U291cmNlLzM=
", name: "bar" }) { source { name } } }
```

** Result **

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

#### Destroy Source

** Query **

```json
mutation destroy { destroySource(input: { clientMutationId: "1", id: "U291cmNlLzM=
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroySource": {
      "deletedId": "U291cmNlLzM=\n"
    }
  }
}
```

#### Read Source

** Query **

```json
query read { root { sources { edges { node { name } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "sources": {
        "edges": [
          {
            "node": {
              "name": "TENWUKVGOU"
            }
          },
          {
            "node": {
              "name": "KHFUCPRJNR"
            }
          }
        ]
      }
    }
  }
}
```

#### Update Team

** Query **

```json
mutation update { updateTeam(input: { clientMutationId: "1", id: "VGVhbS8x
", name: "bar" }) { team { name } } }
```

** Result **

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

#### Create Team

** Query **

```json
mutation create { createTeam(input: {name: "test", clientMutationId: "1"}) { team { id } } }
```

** Result **

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

#### Destroy Api Key

** Query **

```json
mutation destroy { destroyApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzI=
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyApiKey": {
      "deletedId": "QXBpS2V5LzI=\n"
    }
  }
}
```

#### Read Media

** Query **

```json
query read { root { medias { edges { node { url } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "medias": {
        "edges": [
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          },
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          }
        ]
      }
    }
  }
}
```

#### Destroy Media

** Query **

```json
mutation destroy { destroyMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyMedia": {
      "deletedId": "TWVkaWEvMQ==\n"
    }
  }
}
```

#### Read Collection Source

** Query **

```json
query read { root { sources { edges { node { projects { edges { node { title } } }, accounts { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

** Result **

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
                      "title": "NPBNTCFPLA"
                    }
                  },
                  {
                    "node": {
                      "title": "VSLGGYALDE"
                    }
                  }
                ]
              },
              "accounts": {
                "edges": [
                  {
                    "node": {
                      "url": "https://www.youtube.com/user/MeedanTube"
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

#### Update Team User

** Query **

```json
mutation update { updateTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
", team_id: 2 }) { team_user { team_id } } }
```

** Result **

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

#### Create Project Source

** Query **

```json
mutation create { createProjectSource(input: {source_id: 2, project_id: 1, clientMutationId: "1"}) { project_source { id } } }
```

** Result **

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

#### Update Account

** Query **

```json
mutation update { updateAccount(input: { clientMutationId: "1", id: "QWNjb3VudC8x
", user_id: 3 }) { account { user_id } } }
```

** Result **

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

#### Read Object Project

** Query **

```json
query read { root { projects { edges { node { user { name } } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "user": {
                "name": "JIHFIGHWXU"
              }
            }
          },
          {
            "node": {
              "user": {
                "name": "QPNBZEOGUU"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update Project Source

** Query **

```json
mutation update { updateProjectSource(input: { clientMutationId: "1", id: "UHJvamVjdFNvdXJjZS8x
", source_id: 3 }) { project_source { source_id } } }
```

** Result **

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

#### Create Project

** Query **

```json
mutation create { createProject(input: {title: "test", clientMutationId: "1"}) { project { id } } }
```

** Result **

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

#### Update Api Key

** Query **

```json
mutation update { updateApiKey(input: { clientMutationId: "1", id: "QXBpS2V5LzI=
", application: "bar" }) { api_key { application } } }
```

** Result **

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

#### Read Object Team User

** Query **

```json
query read { root { team_users { edges { node { team { name }, user { name } } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "team_users": {
        "edges": [
          {
            "node": {
              "team": {
                "name": "VOKITMOUKD"
              },
              "user": {
                "name": "HRNPCHDJCC"
              }
            }
          },
          {
            "node": {
              "team": {
                "name": "SRKKNIALMF"
              },
              "user": {
                "name": "BWMMZXGXTP"
              }
            }
          }
        ]
      }
    }
  }
}
```

#### Update Project

** Query **

```json
mutation update { updateProject(input: { clientMutationId: "1", id: "UHJvamVjdC8x
", title: "bar" }) { project { title } } }
```

** Result **

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

#### Read Collection Project

** Query **

```json
query read { root { projects { edges { node { sources { edges { node { name } } }, medias { edges { node { url } } }, project_sources { edges { node { project_id } } } } } } } }
```

** Result **

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
                      "name": "RGMVRVPERN"
                    }
                  },
                  {
                    "node": {
                      "name": "UYVZDAWBMC"
                    }
                  }
                ]
              },
              "medias": {
                "edges": [
                  {
                    "node": {
                      "url": "https://www.youtube.com/user/MeedanTube"
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

#### Read Comment

** Query **

```json
query read { root { comments { edges { node { text } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "comments": {
        "edges": [
          {
            "node": {
              "text": "CVQEEJDFWFQALVWFKKYZHKULBXNSZSDLEEKCYICHEHTWZEIWHM"
            }
          },
          {
            "node": {
              "text": "IMTIPERRGMGMWCSGNGSCYAPVQEDJIQVBORURGISFJAARKKJZSS"
            }
          }
        ]
      }
    }
  }
}
```

#### Update Media

** Query **

```json
mutation update { updateMedia(input: { clientMutationId: "1", id: "TWVkaWEvMQ==
", user_id: 3 }) { media { user_id } } }
```

** Result **

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

#### Read Project

** Query **

```json
query read { root { projects { edges { node { title } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "projects": {
        "edges": [
          {
            "node": {
              "title": "YOTBWQIEOA"
            }
          },
          {
            "node": {
              "title": "DAQSHNRTNS"
            }
          }
        ]
      }
    }
  }
}
```

#### Read Team

** Query **

```json
query read { root { teams { edges { node { name } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "teams": {
        "edges": [
          {
            "node": {
              "name": "SFRQCTXCCT"
            }
          },
          {
            "node": {
              "name": "KSIGUMGSJT"
            }
          }
        ]
      }
    }
  }
}
```

#### Read Collection Account

** Query **

```json
query read { root { accounts { edges { node { medias { edges { node { url } } } } } } } }
```

** Result **

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
                      "url": "https://www.youtube.com/user/MeedanTube"
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

#### Read Team User

** Query **

```json
query read { root { team_users { edges { node { user_id } } } } }
```

** Result **

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

#### Destroy Team User

** Query **

```json
mutation destroy { destroyTeamUser(input: { clientMutationId: "1", id: "VGVhbVVzZXIvMQ==
" }) { deletedId } }
```

** Result **

```json
{
  "data": {
    "destroyTeamUser": {
      "deletedId": "VGVhbVVzZXIvMQ==\n"
    }
  }
}
```

#### Read Account

** Query **

```json
query read { root { accounts { edges { node { url } } } } }
```

** Result **

```json
{
  "data": {
    "root": {
      "accounts": {
        "edges": [
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          },
          {
            "node": {
              "url": "https://www.youtube.com/user/MeedanTube"
            }
          }
        ]
      }
    }
  }
}
```

#### Create Comment

** Query **

```json
mutation create { createComment(input: {text: "test", clientMutationId: "1"}) { comment { id } } }
```

** Result **

```json
{
  "data": {
    "createComment": {
      "comment": {
        "id": "Q29tbWVudC9BVlc5cEZfSXQ3a2dpSVY3Y19xMQ==\n"
      }
    }
  }
}
```

#### Create Source

** Query **

```json
mutation create { createSource(input: {name: "test", clientMutationId: "1"}) { source { id } } }
```

** Result **

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

#### Read Collection Team

** Query **

```json
query read { root { teams { edges { node { team_users { edges { node { user_id } } }, users { edges { node { name } } } } } } } }
```

** Result **

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
                      "user_id": 3
                    }
                  },
                  {
                    "node": {
                      "user_id": 4
                    }
                  }
                ]
              },
              "users": {
                "edges": [
                  {
                    "node": {
                      "name": "XCAQKZWKGU"
                    }
                  },
                  {
                    "node": {
                      "name": "VHTODLKRSJ"
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

#### Create Team User

** Query **

```json
mutation create { createTeamUser(input: {team_id: 1, user_id: 2, clientMutationId: "1"}) { team_user { id } } }
```

** Result **

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

#### Read Api Key

** Query **

```json
query read { root { api_keys { edges { node { application } } } } }
```

** Result **

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

