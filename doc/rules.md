### Rules

Rules are way to perform some sequence of automatic actions based on a set of conditions that are met. This documentation explains how to add new conditions or actions. For both conditions and actions, the steps are almost the same and need to be done only on Check API side... nothing should be needed on the clients side (including Check Web).

1. Choose a unique identifier for your new condition or action (the identifier should contain only lowercase letters and underlines) and add it to the `RULES` or `ACTIONS` constants, in `app/models/concerns/team_rules.rb`
2. Add a method with the same name as the identifier defined above to the `Rules` module or to the `Actions` module, in that same `app/models/concerns/team_rules.rb` file... remember that a condition should always return a boolean value (true or false)
3. Add the new condition or action to the JSON Schema file template, in `public/rules_json_schema.json` (maybe in the future that file will be auto-generated, but for now it's a manual step)
4. The rule name should be localized, so please add the new localizables to `config/locales/en.yml`
5. Conditions and actions can have conditional sub-fields - additional fields that can be used to provide more parameters to the condition or action - those are defined in the JSON Schema file as well
