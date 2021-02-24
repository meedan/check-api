## Check API

[![Code Climate](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/gpa.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Test Coverage](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/coverage.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/coverage)
[![Issue Count](https://codeclimate.com/repos/58bdc058359261025a0020fa/badges/be660888a1cd1f246167/issue_count.svg)](https://codeclimate.com/repos/58bdc058359261025a0020fa/feed)
[![Travis](https://travis-ci.org/meedan/check-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

Part of the [Check platform](https://meedan.com/check). Refer to the [main repository](https://github.com/meedan/check) for instructions.


#### Misc

To update a given Team of `ID` to use a model of `MODEL_NAME` when storing and marking content as similar within the `Alegre` service:
```
bundle exec rake check:set_language_model_for_alegre_team_bot_installation['team_id:[ID]','model_name:[MODEL_NAME]']
```