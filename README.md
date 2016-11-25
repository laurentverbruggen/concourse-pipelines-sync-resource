# Concourse Pipelines Sync Resource

Will keep pipelines from a JSON configuration file in sync with pipelines in an actual concourse instance.
The purpose is to allow repositories to make changes to pipelines in Git and have them synced to concourse without the need to fly on the command line.
Using this with the [Concourse Pipelines Discovery Resource](https://github.com/laurentverbruggen/concourse-pipelines-discovery-resource) adds the possibility to dynamically create the JSON configuration file.

## Installing

Use this resource by adding the following to the `resource_types` section of a pipeline config:

```yaml
resource_types:
- name: concourse-pipelines-sync
  type: docker-image
  source:
    repository: laurentverbruggen/concourse-pipelines-sync-resource
```

See [concourse docs](http://concourse.ci/configuring-resource-types.html) for more details on adding `resource_types` to a pipeline config.

## Source Configuration

```yaml
resources:
- name: pipelines-sync
  type: concourse-pipelines-sync
  source:
    team: main
    username: {{concourse-username}}
    password: {{concourse-password}}
```

* `username`: *Required.* Basic auth username for authenticating to the team. Basic Auth must be enabled for the team.

* `password`: *Required.* Basic auth password for authenticating to the team. Basic Auth must be enabled for the team.

* `team`: *Optional (default: main).* Name of team. Equivalent of `-n team-name` in `fly` login command.

* `atc`: *Optional (default: $ATC_EXTERNAL_URL).*  URL of your concourse instance e.g. `https://my-concourse.com`.
If not specified, the resource defaults to the `ATC_EXTERNAL_URL` environment variable, meaning it will always target the same concourse that created the container.

* `insecure`: *Optional (default: false).* Connect to Concourse insecurely - i.e. skip SSL validation. Defaults to false if not provided.


## Behavior

### `check`: No-Op

### `in`: No-Op

### `out`: Add pipeline configuration to concourse.

Add pipeline configuration to concourse source. Pipelines can be passed either dynamically through a file or statically with configuration.

#### Static

```yaml
- get: discover
- put: pipelines-sync
  params:
    inject: true
    config:
      pipelines:
      - name: discovery
        config: discover/pipeline.json
```

#### Dynamic

```yaml
- get: discover
- put: pipelines-sync
  params:
    sync: true
    start: true
    config:
      file: discover/discovery.json
```

#### Parameters

* `config`: *Required.* Either add a configuration file or statically define all configuration to include pipelines in concourse instance

  * `file`: *Optional.* The name of the JSON file containing pipeline configuration for this source.
  The configuration can define a list of pipelines as described below.

  * `pipelines`: *Optional.* List of pipelines where each pipeline holds the following fields:

      * `name`: *Required.* Name of the pipeline

      * `config`: *Required.* Relative path (from source config file) to configuration file for pipeline

      * `vars`: *Optional.* Variables that can be passed to pipeline creation, see [fly documentation](https://concourse.ci/fly-set-pipeline.html) for more information.
      These variables take precedence over the variables defined in source (top level).

      * `vars_from`: *Optional.* Variable files that can be passed to pipeline creation, see [fly documentation](https://concourse.ci/fly-set-pipeline.html) for more information.
      The variables defined in the files take precedence over the variables defined in source (top level).

* `sync`: *Optional (default: false).* Set to true to enable actual mirroring. This means it will remove all pipelines matching a specific `reference if they are no longer included in configuration.

* `reference`: *Optional (default: `(${BUILD_PIPELINE_NAME} > ${BUILD_JOB_NAME})`).* Reference used for tracking previously included pipelines.
Used when syncing so pipelines that no longer exist in source can be removed. This can't be empty as this would remove all pipelines when syncing is enabled. Following placeholders can be used: `BUILD_PIPELINE_NAME`, `BUILD_JOB_NAME`.

* `inject`: *Optional (default: false).* Allows you to include newly created pipelines in a separate group of the current pipeline.
The name of the group will be the name of the pipeline you would create without inject enabled. If no group was defined yet, all current jobs/resources will be grouped under `pipeline_group`.
When inject is enabled, the sync and start configuration will be ignored.
Groups that are defined in pipeline configuration files will be ignored since it would be impossible to distinguish the injected from the original ones without renaming them.

* `pipeline_group`: *Optional (default: original).* Only applicable when using `inject`. This will be the name used to group all jobs/resources in current pipeline.

* `start`: *Optional (default: false).* In concourse newly created pipelines are paused by default. This option allows you to automatically start them.

* `vars`: *Optional.* List of variables to add to all pipelines on creation, see [fly documentation](https://concourse.ci/fly-set-pipeline.html) for more information.

* `vars_from`: *Optional.* List of variable files to add to all pipelines on creation, see [fly documentation](https://concourse.ci/fly-set-pipeline.html) for more information.
