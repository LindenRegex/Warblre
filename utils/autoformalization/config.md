## Step 1 install & configure opencode
### Install
```
curl -fsSL https://opencode.ai/install | bash
```
Type `opencode` on your temrinal. You need to restart it for it to work

### Configure provider 
```
echo '{
  "$schema": "https://opencode.ai/config.json",
  "provider": {
    "myprovider": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "EPFL RCP",
      "options": {
        "baseURL": "https://inference.rcp.epfl.ch/v1"
      },
      "models": {
        "moonshotai/Kimi-K2.5": {
          "name": "moonshotai/Kimi-K2.5",
          "max_tokens": 1000
        },
        "moonshotai/Kimi-K2.6": {
          "name": "moonshotai/Kimi-K2.6",
          "max_tokens": 1000
        }
      }
    }
  }
}' > ~/.config/opencode/opencode.json
```
This will create the file ~/.config/opencode/opencode.json with 2 models, you can select those model on opencode by running ctrl + p and select change model, this is not complete yet as we need a key to access these models

### Key configuration
```
echo '{
  "myprovider": {
    "type": "api",
    "key": "<Your key here>"
  }
}' > ~/.local/share/opencode/auth.json
```
Now you have access to the models


### Pipeline
#### Generate the comments
First you need to download the proposal and the ECMA diff on the proposal folder at the root of the project, see example.
The you can use this prompt on opencode to start the correct agent
```
@annotate_rocq, implement the comments for the following proposal : proposals/<your proposal>
```

#### Generate the code
```
@implement_from_comment add the code for the following proposal : proposals/<your proposal>
```

#### Audit
Check for the code file that changed on the specs and give them to the audit tool, check the README on the audit folder

Once we have the result we can use the filtering agent to only keep the usefull one.
```
@filter_audit filter the audit just generated 
```

#### Apply audit
```
@fix_audit_batch use the latest filter result created and the other subagent on your prompt to solve all of those problems
```

<!-- 
#### Generate tests
@test262_converter, use the latest commit on <branch name> to generate the tests  -->

<!-- 
#### Generate tests
@test262_converter, use the latest commit on <branch name> to generate the tests  -->

#### Fix proofs
Configure mcp, ensure rocq-mcp is running
@fix_proofs, fix the admitted proofs
