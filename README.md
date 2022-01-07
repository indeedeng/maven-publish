# Indeed Maven Publishing Service

This project is responsible for building and publishing Indeed projects to Maven Central.

To publish a library to maven central, visit [the github workflow page](https://github.com/indeedeng/maven-publish/actions/workflows/publish.yml),
click `Run Workflow`, then enter the indeedeng repo name and branch to publish. Publications from the default branch will automatically be versioned
as releases. Otherwise, they will be versioned with a dev suffix. Starting a publish workflow requires write access to the maven-publish repo.

Each library repository is only allowed to publish to a certain pattern of artifact paths. This is intended to prevent an internal bad actor from publishing
library artifacts which do not belong to them. This pattern list is stored in verify.sh. Modifying this file (or any file in this repository) requires being
listed in the `Restrict who can push to matching branches` user list in the Branch settings of this maven-publish repo.
