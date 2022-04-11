## Check API

[![Test Coverage](https://api.codeclimate.com/v1/badges/583c7f562a78e7039e13/test_coverage)](https://codeclimate.com/github/meedan/check-api/test_coverage)
[![Maintainability](https://api.codeclimate.com/v1/badges/583c7f562a78e7039e13/maintainability)](https://codeclimate.com/github/meedan/check-api/maintainability)
[![Travis](https://travis-ci.org/meedan/check-api.svg?branch=develop)](https://travis-ci.org/meedan/check-api/)

Part of the [Check platform](https://meedan.com/check). Refer to the [main repository](https://github.com/meedan/check) for instructions.


#### Misc

To update a given Team of `ID` to use a model of `MODEL_NAME` when storing and marking content as similar within the `Alegre` service:
```
bundle exec rake check:set_language_model_for_alegre_team_bot_installation['[ID]','[MODEL_NAME]']
```
