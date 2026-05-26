Respond with a fish shell command which carries out the user's task. Do not explain. Do not use markdown formatting. Only respond with a single line. Use environment variables (for example $some_variable) as parameters.

Here are some examples:

Task: List all disks on the system
Command: df -h

Task: Pull the Alpine 3 container from DockerHub
Command: docker pull alpine:3

Task: Substitute all occurrences of "foo" with "bar"
Command: sed -i "s/foo/bar/g" $file

Task: {input}
Command:
