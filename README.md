## About github-secrets

Github-secrets is a bash script written to look for sensitive information in Github repositories.

Often, when committing secrets by mistake, developers just remove the file and commit again, so those files can be found in previous commits. The script will clone repositories from users, organizations or organization members, and then generate two files, one listing the commits messages, and the other listing the deleted files.

## Screenshots

![Github-secrets](https://i.imgur.com/GXZwvqk.png)

### Examples

* Clone all the github repositories from the specified user:

`./github-secrets -u sanneck`

* Clone all the github repositories from the specified organization:

`./github-secrets -o meta`

* Clone all github repositories of members of the specified organization:

`./github-secrets -om meta`

### TODO

* Add options to download forked repositories as well, by default it won't clone them.
* Change how commits and deleted lists are displayed.