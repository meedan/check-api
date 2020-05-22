# Check API

Before you start, make sure you have a team setup on Check and an API key. Ask the Check team for an API key for your team if you don't have one.
You can make requests either using a command line tool, like cURL, or use our API Explorer: https://check-api.checkmedia.org/graphiql.
If you want to use our API Explorer, you just need to paste the GraphQL query on the left and press the "play" button on top.
If you prefer to use a command line tool, the format is: `curl -XPOST -H 'X-Check-Token: <API Key>' -d "query=<query>" https://check-api.checkmedia.org/api/graphql`.

The available queries are:

## Get team information

_Query_
```
query {
  me {
    current_team {
      id
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "me": {
      "current_team": {
        "id": "VGVhbS81MjY=\n",
        "dbid": 526
      }
    }
  }
}
```

## Get list of projects

List all projects under the current team but ask only for the `title` field of each project:

_Query_
```
query {
  me {
    current_team {
      projects {
        edges {
          node {
            title
          }
        }
      }
    }
  }
}
```

_Response_
```
{
  "data": {
    "me": {
      "current_team": {
        "projects": {
          "edges": [
            {
              "node": {
                "title": "Test"
              }
            },
            {
              "node": {
                "title": "Created by the bot"
              }
            }
          ]
        }
      }
    }
  }
}
```

## Create project

Using the team id from that first query, you can create a project:

_Query_
```
mutation {
  createProject(input: {
    clientMutationId: "1",
    title: "Created by the bot",
    team_id: 526
  }) {
    project {
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "createProject": {
      "project": {
        "dbid": 778
      }
    }
  }
}
```

## Get tasks that can be auto-responded

When creating medias, it's possible to auto-respond to tasks that are created automatically for any created media. We can configure those tasks. Feel free to suggest those tasks. You can run a query to know which are those tasks, using the project id (from the last query above) and the team id (from the first query above):

_Query_
```
query {
  project(ids: "778,526") {
    auto_tasks
  }
}
```

_Response_
```
{
  "data": {
    "project": {
      "auto_tasks": [
        {
          "label": "When?",
          "type": "datetime",
          "description": "When did the incident take place",
          "projects": [],
          "slug": "when"
        },
        {
          "label": "Where?",
          "type": "geolocation",
          "description": "Where did the incident take place?",
          "projects": [],
          "slug": "where"
        }
      ]
    }
  }
}
```

The `slug` is what is used to identify the task when creating a media with a response to an auto-task.

## Add new auto-task

The query below adds a new auto-task and gets the updated list of auto-tasks as response. The `type` inside `add_auto_task` can be `geolocation`, `datetime`, `free_text`, `single_choice`, `multiple_choice` or `image_upload`. For the choice types, an additional field `options` should exist inside `add_auto_task`, which is a JSON string with format `"[{\"label\":\"Option A\"},{\"label\":\"Option B\"}]"`.

_Query_
```
mutation {
 updateTeam(input: {
    clientMutationId: "1",
    id: "VGVhbS81MjY=\n",
    add_auto_task: "{
      \"label\": \"Who?\",
      \"type\": \"free_text\",
      \"description\": \"\"
    }"
  }) {
    team {
      projects(last: 1) {
        edges {
          node {
            auto_tasks
          }
        }
      }
    }
  }
}
```

_Response_

```
{
  "data": {
    "updateTeam": {
      "team": {
        "projects": {
          "edges": [
            {
              "node": {
                "auto_tasks": [
                  {
                    "label": "When?",
                    "type": "datetime",
                    "description": "When did the incident take place",
                    "projects": [],
                    "slug": "when"
                  },
                  {
                    "label": "Where?",
                    "type": "geolocation",
                    "description": "Where did the incident take place?",
                    "projects": [],
                    "slug": "where"
                  },
                  {
                    "label": "Who?",
                    "type": "free_text",
                    "description": "",
                    "slug": "who"
                  }
                ]
              }
            }
          ]
        }
      }
    }
  }
}
```

## Create medias

You can now add medias (optionally with responses to the auto-tasks) to the project you created before:

_Query_
```
mutation {
  createProjectMedia(input: {
    clientMutationId: "1",
    project_id: 878,
    quote: "This is a claim",
    url: "",
    quote_attributions: "{\"name\":\"Source of this claim\"}",
    set_tasks_responses: "{
      \"when\": \"2017-10-02 15:07 +3 BRT\",
      \"where\": \"{\\\"type\\\":\\\"Feature\\\",\\\"geometry\\\":{\\\"type\\\":\\\"Point\\\",\\\"coordinates\\\":[-12.9016241,-38.4198075]},\\\"properties\\\":{\\\"name\\\":\\\"Salvador\\\"}}\"
    }"
  }) {
    project_media {
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "createProjectMedia": {
      "project_media": {
        "dbid": 4933
      }
    }
  }
}
```

As we can see above, the `geolocation` task response should be a valid [GeoJSON](http://geojson.org/).

The `url` and `quote` can't be both defined at the same time. It's one or the other. If the `quote` field is set, it means you're creating a claim. If the `url` field is set, it means you're creating a report of type "link".

## Updating media

We can update media using the GraphQL (Base 64) id. In the example below, we change the description of a media:

_Query_
```
mutation {
  updateProjectMedia(input: {
    clientMutationId: "1",
    id: "UHJvamVjdE1lZGlhLzY5OTI=\n",
    embed: "{\"description\":\"Changing description\"}"
  }) {
    project_media {
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "updateProjectMedia": {
      "project_media": {
        "dbid": 6992
      }
    }
  }
}
```

## Add comment to media

You can also add comments to medias:

_Query_
```
mutation {
  createComment(input: {
    clientMutationId: "1",
    text: "A comment by a bot",
    annotated_id: "4933",
    annotated_type: "ProjectMedia"
  }) {
    comment {
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "createComment": {
      "comment": {
        "dbid": "37457"
      }
    }
  }
}
```

## Get list of medias

Take a look at [GraphiQL](https://check-api.checkmedia.org/graphiql) interface in order to see all fields that you can read. On the example below, we get the URL, tasks and task responses of all medias marked as `verified` and that belong to project with database id 778.

_Query_
```
query {
  search(query: "{\"verification_status\":[\"verified\"],\"projects\":[\"778\"]}") {
    medias(first: 10000) {
      edges {
        node {
          tasks(first: 10000) {
            edges {
              node {
                label
                first_response_value
              }
            }
          }
          media {
            url
          }
        }
      }
    }
  }
}
```

_Response_
```
{
  "data": {
    "search": {
      "medias": {
        "edges": [
          {
            "node": {
              "tasks": {
                "edges": [
                  {
                    "node": {
                      "label": "Who?",
                      "first_response_value": "Jaguar"
                    }
                  },
                  {
                    "node": {
                      "label": "Where?",
                      "first_response_value": "Zoo"
                    }
                  },
                  {
                    "node": {
                      "label": "When?",
                      "first_response_value": "A couple weeks ago"
                    }
                  }
                ]
              },
              "media": {
                "url": "https://twitter.com/g1/status/885552426874523648"
              }
            }
          }
        ]
      }
    }
  }
}
```

## Add a tag to a media

You need to have the id of the media that you want to add a tag to. This is the last number in a Check item URL. For example, for https://checkmedia.org/test/project/73/media/104, the id is 104. That id goes into `annotated_id` in the query below.

_Query_
```
mutation {
  createTag(input:{
    clientMutationId: "1",
    tag: "foo",
    annotated_id: "104",
    annotated_type: "ProjectMedia"
  }) {
    tagEdge {
      node {
        dbid
      }
    }
  }
}
```

_Response_
```
{
  "data": {
    "createTag": {
      "tagEdge": {
        "node": {
          "dbid": "792871"
        }
      }
    }
  }
}
```

## Add related item

In order to add a related item, you must have the Base 64 id of the child item and the incremental id of the parent item. In the example below, 36064 is the incremental id of the parent item and the Base 64 id of the child item is `UHJvamVjdE1lZGlhLzM2MDY3\n`.

_Query_
```
mutation {
  updateProjectMedia(input:{
    clientMutationId: "1",
    id:"UHJvamVjdE1lZGlhLzM2MDY3\n",
    related_to_id: 36064
  }) {
    related_to {
      dbid
    }
  }
}
```

_Response_
```
{
  "data": {
    "updateProjectMedia": {
      "related_to": {
        "dbid": 36064
      }
    }
  }
}
```
